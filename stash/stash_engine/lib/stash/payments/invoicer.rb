# this require needed in tests, but not really in app, though it doesn't hurt anything
require_relative '../../../app/helpers/stash_engine/application_helper'
require 'stripe'

# rubocop:disable Metrics/ClassLength
module Stash
  module Payments
    class Invoicer

      # this drops in a couple methods and makes "def filesize(bytes, decimal_points = 2)" available
      # to output digital storage sizes
      include StashEngine::ApplicationHelper

      attr_reader :resource, :curator

      def initialize(resource:, curator:)
        @resource = resource
        @curator = curator
      end

      # For an end-user, generate an invoice with a single charge
      # based on the DPC, and immediately finalize the invoice.
      def charge_user_via_invoice
        set_api_key
        customer_id = stripe_user_customer_id
        return unless customer_id.present?
        create_invoice_items_for_dpc(customer_id)
        invoice = create_invoice(customer_id)
        resource.identifier.invoice_id = invoice.id
        resource.identifier.save
        invoice.send_invoice
      end

      # For a journal, generate an invoice item for the DPC.
      # Don't create the actual invoice, because we don't want to
      # send it until the end of the month.
      def charge_journal_via_invoice
        set_api_key
        customer_id = stripe_journal_customer_id
        return unless customer_id.present?
        # the following line was creating invoice_item from return value, but didn't seem used anywhere
        create_invoice_items_for_dpc(customer_id)
        resource.identifier.invoice_id = invoice_item&.id
        resource.identifier.save
      end

      def external_service_online?
        set_api_key
        latest = StashEngine::Identifier.where.not(invoice_id: nil).order(updated_at: :desc).first
        return false unless latest.present?
        Stripe::Charge.retrieve(latest.invoice_id).present?
      end

      # takes a size and returns overage charges in cents
      def overage_charges
        overage_chunks * StashEngine.app.payments.additional_storage_chunk_cost
      end

      def ds_size
        # generally we should have populated this into the identifier from Merritt by callback, but the sum of
        # all the file sizes for a version is a fallback
        resource.identifier.storage_size || StashEngine::FileUpload.where(resource_id: resource.id).sum(:upload_file_size)
      end

      def overage_bytes
        size_in_bytes = ds_size
        return 0 if size_in_bytes <= StashEngine.app.payments.large_file_size

        size_in_bytes - StashEngine.app.payments.large_file_size
      end

      def overage_chunks
        over_bytes = overage_bytes
        return 0 if over_bytes == 0

        (over_bytes / StashEngine.app.payments.additional_storage_chunk_size).ceil
      end

      def overage_message
        msg = <<~MESSAGE
          Oversize submission charges for #{resource.identifier}. Overage amount is #{filesize(overage_bytes)} @
          #{ActionController::Base.helpers.number_to_currency(StashEngine.app.payments.additional_storage_chunk_cost / 100)}
          per #{filesize(StashEngine.app.payments.additional_storage_chunk_size)} or part thereof
          over #{filesize(StashEngine.app.payments.large_file_size)} (see https://datadryad.org/stash/publishing_charges for details)
        MESSAGE
        msg.strip.gsub(/\s+/, ' ')
      end

      # Helper methods
      # ------------------------------------------
      private

      def set_api_key
        Stripe.api_key = StashEngine.app.payments.key
      end

      # this is mostly just long because of long text & formatting text
      def create_invoice_items_for_dpc(customer_id)
        items = [Stripe::InvoiceItem.create(
          customer: customer_id,
          amount: StashEngine.app.payments.data_processing_charge,
          currency: 'usd',
          description: "Data Processing Charge for #{resource.identifier} (#{filesize(ds_size)})"
        )]
        over_chunks = overage_chunks
        if over_chunks.positive?
          items.push(Stripe::InvoiceItem.create(
                       customer: customer_id,
                       unit_amount: StashEngine.app.payments.additional_storage_chunk_cost,
                       currency: 'usd',
                       quantity: over_chunks,
                       description: overage_message
                     ))
        end
        items
      end

      def create_invoice(customer_id)
        Stripe::Invoice.create(
          auto_advance: true,
          collection_method: 'send_invoice',
          customer: customer_id,
          days_until_due: 30,
          description: 'Dryad deposit ' + resource.identifier.to_s + ', ' + resource.title,
          metadata: { 'curator' => curator.name }
        )
      end

      def create_customer(author)
        Stripe::Customer.create(
          name: author.author_standard_name,
          email: author.author_email
        )
      end

      def stripe_user_customer_id
        author = StashEngine::Author.primary(resource.id)
        return if author.blank?
        return if author.author_email.blank?
        return author.stripe_customer_id if author.stripe_customer_id.present?

        # Check whether this author has previously submitted and obtained a customer_id
        customer_id = lookup_prior_stripe_customer_id(author.author_email)
        # Otherwise we need to generate a new one
        customer_id = create_customer(author).id unless customer_id.present?
        # Update the current primary author with the stripe customer id
        author.update(stripe_customer_id: customer_id)
        customer_id
      end

      def stripe_journal_customer_id
        resource.identifier&.journal_customer_id
      end

      def lookup_prior_stripe_customer_id(email)
        # Each resource has its own set of authors so look through all the prior datasets
        # for the first author to see if they have a stripe_customer_id associated with this email
        StashEngine::Author.where(author_email: email).where.not(stripe_customer_id: nil).order(:id).first&.stripe_customer_id
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength

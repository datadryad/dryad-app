# this require needed in tests, but not really in app, though it doesn't hurt anything
require_relative '../../../app/helpers/stash_engine/application_helper'
require 'stripe'

module Stash
  module Payments
    class Invoicer

      # this drops in a couple methods and makes "def filesize(bytes, decimal_points = 2)" available
      # to output digital storage sizes
      include StashEngine::ApplicationHelper

      attr_reader :resource, :curator

      # Settings used by all Stripe services
      Stripe.api_key = APP_CONFIG.payments.key
      Stripe.api_version = '2025-03-31.basil'

      def self.find_recent_voids
        d = Date.today - 2.months
        Stripe::Invoice.list({ created: { gt: d.to_time.to_i }, status: 'void' }).data
      end

      def self.data_processing_charge(identifier:)
        return APP_CONFIG.payments.data_processing_charge unless APP_CONFIG.payments&.dpc_change_date

        if identifier.created_at >= APP_CONFIG.payments.dpc_change_date
          APP_CONFIG.payments.data_processing_charge_new
        else
          APP_CONFIG.payments.data_processing_charge
        end
      end

      def initialize(resource:, curator:)
        @resource = resource
        @curator = curator
        @has_overage_line_item = false
      end

      # For an end-user, generate an invoice with a single charge
      # based on the DPC, and immediately finalize the invoice.
      def charge_user_via_invoice
        customer_id = stripe_user_customer_id
        return unless customer_id.present?

        invoice = create_invoice(customer_id)
        create_invoice_items_for_dpc(customer_id, invoice.id)
        resource.identifier.payment_id = invoice.id
        resource.identifier.payment_type = stripe_user_waiver? ? 'waiver' : 'stripe'
        resource.identifier.save
        res = invoice.send_invoice

        resource.identifier.update(last_invoiced_file_size: ds_size) if @has_overage_line_item
        res
      end

      def check_new_overages(prev_size)
        customer_id = stripe_user_customer_id
        return unless customer_id.present?

        lfs = APP_CONFIG.payments.large_file_size
        overage_step = APP_CONFIG.payments.additional_storage_chunk_size
        return unless ds_size > lfs && (ds_size / overage_step).floor > (prev_size / overage_step).floor

        over = ds_size - [prev_size, lfs].max
        invoice = create_invoice(customer_id)
        create_invoice_overages(over, customer_id, invoice.id)
        invoice.send_invoice
        resource.identifier.update(last_invoiced_file_size: ds_size) if @has_overage_line_item
        CurationService.new(
          resource: resource, note: "New overage invoice sent with ID: #{invoice.id}", status: resource.current_curation_status, user_id: 0
        ).process
      end

      def external_service_online?
        latest = StashEngine::Identifier.where.not(payment_id: nil).order(updated_at: :desc).first
        return false unless latest.present?

        Stripe::Charge.retrieve(latest.payment_id).present?
      end

      def create_customer(name, email)
        Stripe::Customer.create(name: name, email: email)
      end

      def retrieve_customer(id)
        Stripe::Customer.retrieve(id)
      end

      def lookup_prior_stripe_customer_id(email)
        # Each resource has its own set of authors so look through all the prior datasets
        # for the first author to see if they have a stripe_customer_id associated with this email
        StashEngine::Author.where(author_email: email).where.not(stripe_customer_id: nil).order(:id).first&.stripe_customer_id
      end

      def ds_size
        # Only charge based on the files present in the item at time of publication
        resource.total_file_size || 0
      end

      def overage_bytes
        return 0 if ds_size <= APP_CONFIG.payments.large_file_size

        ds_size - APP_CONFIG.payments.large_file_size
      end

      def overage_chunks(over_bytes)
        return 0 if over_bytes == 0

        (over_bytes / APP_CONFIG.payments.additional_storage_chunk_size).ceil
      end

      def overage_message(over_bytes)
        msg = <<~MESSAGE
          Oversize submission charges for #{resource.identifier}. Overage amount is #{filesize(over_bytes)} @
          #{ActionController::Base.helpers.number_to_currency(APP_CONFIG.payments.additional_storage_chunk_cost / 100)}
          per #{filesize(APP_CONFIG.payments.additional_storage_chunk_size)} or part thereof
          over #{filesize(APP_CONFIG.payments.large_file_size)} (see https://datadryad.org/publishing_charges for details)
        MESSAGE
        msg.strip.gsub(/\s+/, ' ')
      end

      private

      def create_invoice_items_for_dpc(customer_id, invoice_id)
        dpc = Invoicer.data_processing_charge(identifier: resource.identifier)
        items = [Stripe::InvoiceItem.create(
          customer: customer_id,
          invoice: invoice_id,
          amount: dpc,
          currency: 'usd',
          description: "Data processing charge for #{resource.identifier} (#{filesize(ds_size)})"
        )]
        items.concat(create_invoice_overages(overage_bytes, customer_id, invoice_id))
        # For users with a waiver, add line waiving invoice amount
        if stripe_user_waiver?
          over_chunks = overage_chunks(overage_bytes)
          overcharge = over_chunks.positive? ? APP_CONFIG.payments.additional_storage_chunk_cost * over_chunks : 0
          items.push(Stripe::InvoiceItem.create(
                       customer: customer_id,
                       invoice: invoice_id,
                       amount: -(dpc + overcharge),
                       currency: 'usd',
                       description: "Waiver of charges for #{resource.identifier} (#{filesize(ds_size)})"
                     ))
        end
        items
      end

      def create_invoice_overages(over_bytes, customer_id, invoice_id)
        over_chunks = overage_chunks(over_bytes)
        items = []
        if over_chunks.positive?
          items.push(Stripe::InvoiceItem.create(
                       customer: customer_id,
                       invoice: invoice_id,
                       unit_amount_decimal: APP_CONFIG.payments.additional_storage_chunk_cost,
                       currency: 'usd',
                       quantity: over_chunks,
                       description: overage_message(over_bytes)
                     ))
          @has_overage_line_item = true
        end
        items
      end

      def create_invoice(customer_id)
        Stripe::Invoice.create(
          auto_advance: true,
          collection_method: 'send_invoice',
          customer: customer_id,
          days_until_due: 30,
          description: "Dryad deposit #{resource.identifier}, #{resource.title}",
          metadata: { 'curator' => curator&.name }
        )
      end

      def stripe_user_waiver?
        resource.identifier.payment_type == 'waiver'
      end

      def stripe_user_customer_id
        author = resource.owner_author
        return if author.blank?
        return if author.author_email.blank?
        return author.stripe_customer_id if author.stripe_customer_id.present?

        # Check whether this author has previously submitted and obtained a customer_id
        customer_id = lookup_prior_stripe_customer_id(author.author_email)
        # Otherwise we need to generate a new one
        customer_id = create_customer(author.author_standard_name, author.author_email).id unless customer_id.present?
        # Update the current primary author with the stripe customer id
        author.update(stripe_customer_id: customer_id)
        customer_id
      end

      def stripe_journal_customer_id
        resource.identifier&.journal&.stripe_customer_id
      end
    end
  end
end

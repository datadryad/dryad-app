# this require needed in tests, but not really in app, though it doesn't hurt anything
require_relative '../../../app/helpers/stash_engine/application_helper'
require 'stripe'

module Stash
  module Payments
    class StripeInvoicer

      # this drops in a couple methods and makes "def filesize(bytes, decimal_points = 2)" available
      # to output digital storage sizes
      include StashEngine::ApplicationHelper

      attr_reader :resource, :curator

      # Settings used by all Stripe services
      Stripe.api_key = APP_CONFIG.payments.key
      Stripe.api_version = '2022-11-15'

      def initialize(resource)
        @resource = resource
        @has_overage_line_item = false
      end

      def create_customer(name, email)
        Stripe::Customer.create(name: name, email: email)
      end

      def lookup_prior_stripe_customer_id(email)
        # Each resource has its own set of authors so look through all the prior datasets
        # for the first author to see if they have a stripe_customer_id associated with this email
        StashEngine::Author.where(author_email: email).where.not(stripe_customer_id: nil).order(:id).first&.stripe_customer_id
      end

      def invoice_created?
        resource.payment.invoice_id.present?
      end

      def create_invoice
        @fees = ResourceFeeCalculatorService.new(resource).calculate({ generate_invoice: true })
        return false if @fees[:total].zero? && !stripe_user_waiver?

        invoice = build_invoice
        create_invoice_items(invoice.id)
        resource.identifier.payment_id = invoice.id
        resource.identifier.payment_type = stripe_user_waiver? ? 'waiver' : 'stripe'
        resource.identifier.save
        res = invoice
        # res = invoice.send_invoice
        resource.identifier.update(last_invoiced_file_size: ds_size)
        res
      end

      private

      def build_invoice
        Stripe::Invoice.create(
          auto_advance: true,
          collection_method: 'send_invoice',
          customer: stripe_user_customer_id,
          days_until_due: 30,
          description: "Dryad deposit #{resource.identifier}, #{resource.title}",
          metadata: { 'curator' => curator&.name }
        )
      end

      def processed_amount(value)
        value * 100
      end

      def line_item_name(fee_key)
        return "#{@fees[:storage_fee_label]} for #{resource.identifier} (#{filesize(ds_size)})" if fee_key.to_s == 'storage_fee'

        PRODUCT_NAME_MAPPER[fee_key]
      end

      def create_invoice_items(invoice_id)
        @fees.except(:storage_fee_label, :total).map do |fee_key, amount|
          next if amount.zero? && !stripe_user_waiver?

          Stripe::InvoiceItem.create(
            customer: stripe_user_customer_id,
            invoice: invoice_id,
            amount: processed_amount(amount),
            currency: 'usd',
            description: line_item_name(fee_key)
          )
        end
      end

      def ds_size
        # Only charge based on the files present in the item at time of publication
        resource.total_file_size || 0
      end

      def stripe_user_waiver?
        resource.identifier.payment_type == 'waiver'
      end

      def stripe_user_customer_id
        return @customer_id if @customer_id

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
        @customer_id = customer_id
      end
    end
  end
end

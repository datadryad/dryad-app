# this require needed in tests, but not really in app, though it doesn't hurt anything
require_relative '../../../app/helpers/stash_engine/application_helper'
require 'stripe'

module Stash
  module Payments
    class StripeInvoicer

      # this drops in a couple methods and makes "def filesize(bytes, decimal_points = 2)" available
      # to output digital storage sizes
      include StashEngine::ApplicationHelper

      attr_reader :resource

      # Settings used by all Stripe services
      Stripe.api_key = APP_CONFIG.payments.key
      Stripe.api_version = '2025-03-31.basil'

      def initialize(resource)
        @resource = resource
      end

      def invoice_created?
        return false unless resource.payment.present?

        resource.payment.invoice_id.present?
      end

      def create_invoice
        return false if invoice_created?

        @fees = ResourceFeeCalculatorService.new(resource).calculate({ generate_invoice: true })
        return false if @fees[:total].zero? && !stripe_user_waiver?

        invoice = build_invoice
        create_invoice_items(invoice.id)
        resource.identifier.payment_id = invoice.id
        resource.identifier.payment_type = stripe_user_waiver? ? 'waiver' : 'stripe'
        resource.identifier.save
        res = invoice.send_invoice
        resource.identifier.update(last_invoiced_file_size: ds_size) if resource.identifier.last_invoiced_file_size.to_i < ds_size
        res
      end

      def invoice_paid?
        invoice = Stripe::Invoice.retrieve(resource.payment.invoice_id)
        return false unless invoice&.status.present?

        if invoice.status == 'void' && invoice.latest_revision.present?
          resource.payment.update(invoice_id: invoice.latest_revision)
          return invoice_paid?
        end
        # one of 'draft', 'open', 'paid', 'uncollectible', or 'void'
        invoice.status == 'paid'
      end

      def handle_customer(invoice_details)
        author = StashEngine::Author.find(invoice_details['author_id'])
        customer_id = lookup_prior_stripe_customer_id(invoice_details['customer_email'])
        unless customer_id.present?
          customer_id = create_customer(
            invoice_details['customer_name'],
            invoice_details['customer_email']
          ).id
        end
        author.update(stripe_customer_id: customer_id)
      end

      private

      def build_invoice
        Stripe::Invoice.create(
          auto_advance: true,
          collection_method: 'send_invoice',
          customer: stripe_user_customer_id,
          days_until_due: 30,
          description: "Dryad deposit #{resource.identifier}, #{resource.title}"
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
        @fees.except(:storage_fee_label, :total, :coupon_id).map do |fee_key, amount|
          next if amount.zero? && !stripe_user_waiver?

          Stripe::InvoiceItem.create(
            customer: stripe_user_customer_id,
            invoice: invoice_id,
            amount: processed_amount(amount),
            currency: 'usd',
            description: line_item_name(fee_key)
            # discounts: [{coupon: 'FEE_WAIVER_100_OFF'}]
          )
        end
      end

      def create_customer(name, email)
        Stripe::Customer.create(name: name, email: email)
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

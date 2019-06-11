module Stash
  module Payments
    class Invoicer
      attr_reader :resource, :curator

      def initialize(resource:, curator:)
        @resource = resource
        @curator = curator
      end

      def charge_via_invoice
        set_api_key
        customer_id = stripe_customer_id
        return unless customer_id.present?
        add_dpc(customer_id)
        invoice = create_invoice(customer_id)
        invoice.auto_advance = true
        resource.identifier.invoice_id = invoice.id
        resource.identifier.save
        invoice.finalize_invoice
      end

      def external_service_online?
        set_api_key
        latest = StashEngine::Identifier.where.not(invoice_id: nil).order(updated_at: :desc).first
        return false unless latest.present?
        Stripe::Charge.retrieve(latest.invoice_id).present?
      end

      # Helper methods
      # ------------------------------------------
      private

      def set_api_key
        Stripe.api_key = StashEngine.app.payments.key
      end

      def add_dpc(customer_id)
        Stripe::InvoiceItem.create(
          customer: customer_id,
          amount: StashEngine.app.payments.data_processing_charge,
          currency: 'usd',
          description: 'Data Processing Charge'
        )
      end

      def create_invoice(customer_id)
        Stripe::Invoice.create(
          customer: customer_id,
          description: 'Dryad deposit ' + resource.identifier.to_s + ', ' + resource.title,
          metadata: { 'curator' => curator.name }
        )
      end

      def create_customer(author)
        Stripe::Customer.create(
          description: author.author_standard_name,
          email: author.author_email
        )
      end

      def stripe_customer_id
        ensure_customer_id_exists
      end

      def ensure_customer_id_exists
        # Retrieve the primary author for the dataset
        author = StashEngine::Author.primary(resource.id)
        return if author.blank?
        # See if the author already has a stripe_customer_id
        customer_id = lookup_prior_stripe_customer_id(author.author_email)
        # Otherwise we need to generate a new one
        customer_id = create_customer(author).id unless customer_id.present?
        # Update the current primary author with the stripe customer id
        author.update(stripe_customer_id: customer_id)
        customer_id
      end

      def lookup_prior_stripe_customer_id(email)
        # Each resource has its own set of authors so look through all the prior records
        # for the first author to see if they have a stripe_customer_id
        StashEngine::Author.where(author_email: email).where.not(stripe_customer_id: nil).order(:id).first&.stripe_customer_id
      end
    end
  end
end

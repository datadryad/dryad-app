module Stash
  module Payments
    class Invoicer
      attr_reader :resource, :curator

      def initialize (resource:, curator:)
        @resource = resource
        @curator = curator
      end
            
      def charge_via_invoice
        Stripe.api_key = StashEngine.app.payments.key
        add_dpc
        invoice = create_invoice
        invoice.auto_advance = true
        resource.identifier.invoice_id = invoice.id
        resource.identifier.save
        invoice.finalize_invoice
      end

      # Helper methods
      # ------------------------------------------
      private
      
      def add_dpc
        Stripe::InvoiceItem.create(
          customer: stripe_customer_id,
          amount: StashEngine.app.payments.data_processing_charge,
          currency: 'usd',
          description: 'Data Processing Charge'
        )
      end
      
      def create_invoice
        Stripe::Invoice.create(
          customer: resource.user.customer_id,
          description: 'Dryad deposit ' + resource.identifier.to_s + ', ' + resource.title,
          metadata: { 'curator' => curator.name }
        )
      end
      
      def stripe_customer_id
        ensure_customer_id_exists
        resource.user.customer_id
      end
      
      def ensure_customer_id_exists
        return unless resource.user.customer_id.nil?
        customer = Stripe::Customer.create(
          description: resource.user.name,
          email: resource.user.email
        )
        resource.user.customer_id = customer.id
        resource.user.save
      end
      
    end
  end
end

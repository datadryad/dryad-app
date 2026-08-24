module Integrations
  class StripeIntegration
    class << self
      def get_balance_transaction(transaction_id)
        return nil unless transaction_id.present?

        return invoice_transaction(transaction_id) if transaction_id.start_with?('in_')
        return payment_intent_transaction(transaction_id) if transaction_id.start_with?('pi_')

        nil
      end

      private

      def payment_intent_transaction(transaction_id)
        return nil if transaction_id.blank?

        Stripe::PaymentIntent.retrieve({ id: transaction_id, expand: ['latest_charge'] }).latest_charge&.balance_transaction
      end

      def invoice_transaction(transaction_id)
        invoice_payment = Stripe::InvoicePayment.list(
          { invoice: transaction_id, status: 'paid' }
        ).data.first
        return nil if invoice_payment.nil?

        payment_intent_transaction(invoice_payment.payment&.payment_intent)
      end

    end
  end
end

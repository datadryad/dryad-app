module Stripe
  module Handlers
    class InvoiceBase
      attr_reader :event, :invoice_id, :payment

      def initialize(event)
        @event = event
        @invoice_id = event.data.object.id
        @payment = ResourcePayment.where(pay_with_invoice: true, invoice_id: invoice_id).last
      end

      private

      def log_status_time_error(action)
        Rails.logger.error("Stripe - #{action} - Could not get status_time for Invoice with ID #{invoice_id}.")
      end

      def invalid_payment_log(action)
        Rails.logger.warn("Stripe - #{action} - No payment record for Invoice with ID #{invoice_id}.")
      end
    end
  end
end

module Stripe
  module Handlers
    class InvoiceBase
      attr_reader :event, :invoice_id, :payment, :invoice

      def initialize(event: nil, invoice: nil)
        if invoice
          @invoice = invoice
        else
          @event = event
          @invoice = event.data.object
        end
        @invoice_id = @invoice.id
        @payment = ResourcePayment.where(pay_with_invoice: true, invoice_id: @invoice_id).last
      end

      private

      def voided_at(stripe_invoice)
        Time.at(stripe_invoice.status_transitions.voided_at.to_i)
      rescue StandardError
        log_status_time_error('invoice.voided')
        Time.current
      end

      def paid_at(stripe_invoice)
        Time.at(stripe_invoice.status_transitions.paid_at.to_i)
      rescue StandardError
        log_status_time_error('invoice.paid')
        Time.current
      end

      def log_status_time_error(action)
        Rails.logger.error("Stripe - #{action} - Could not get status_time for Invoice with ID #{invoice_id}.")
      end

      def invalid_payment_log(action)
        Rails.logger.warn("Stripe - #{action} - No payment record for Invoice with ID #{invoice_id}.")
      end
    end
  end
end

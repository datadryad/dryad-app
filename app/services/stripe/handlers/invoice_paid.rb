module Stripe
  module Handlers
    class InvoicePaid < InvoiceBase

      def call
        if payment.nil?
          invalid_payment_log('invoice.paid')
          return
        elsif payment.paid?
          Rails.logger.warn("Stripe - invoice.paid - Payment record is already marked as paid for Invoice with ID #{invoice_id}.")
          return
        end

        payment.update(
          status: :paid,
          paid_at: status_time,
          status_time: status_time
        )
        CurationService.new(resource: payment.resource, user_id: 0, status: 'queued', note: 'Invoice has been paid').process
      end

      private

      def status_time
        Time.at(@event.data.object.status_transitions.paid_at.to_i)
      rescue StandardError
        log_status_time_error('invoice.paid')
        Time.current
      end
    end
  end
end

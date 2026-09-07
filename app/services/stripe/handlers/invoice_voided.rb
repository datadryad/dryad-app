module Stripe
  module Handlers
    class InvoiceVoided < InvoiceBase

      def call
        if payment.nil?
          invalid_payment_log('invoice.voided')
          return
        end

        payment.update(status: :voided, status_time: status_time)
      end

      private

      def status_time
        Time.at(event.data.object.status_transitions.voided_at.to_i)
      rescue StandardError
        log_status_time_error('invoice.voided')
        Time.current
      end
    end
  end
end

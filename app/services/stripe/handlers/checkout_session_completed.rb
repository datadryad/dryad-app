module Stripe
  module Handlers
    class CheckoutSessionCompleted
      attr_reader :event, :session_id, :payment

      def initialize(event: nil)
        @event = event
        @session_id = event.data.object.id
        @payment = ResourcePayment.where(pay_with_invoice: false, checkout_session_id: session_id).last
      end

      def call
        if payment.nil?
          invalid_payment_log('checkout.session.completed')
          return
        end
        return if payment.paid?

        Stripe::HandlePaymentsService.new(payment).mark_session_paid(session_id, paid_at: status_time)
      end

      private

      def status_time
        Time.at(event.data.object.created.to_i)
      rescue StandardError
        log_status_time_error('checkout.session.completed')
        Time.current
      end

      def log_status_time_error(action)
        Rails.logger.error("Stripe - #{action} - Could not get status_time for session_id #{session_id}.")
      end

      def invalid_payment_log(action)
        Rails.logger.warn("Stripe - #{action} - No payment record for session_id #{session_id}.")
      end
    end
  end
end

module Stripe
  module Handlers
    class ChargeRefunded
      attr_reader :event, :payment_intent, :payment

      def initialize(event: nil)
        @event = event
        @payment_intent = event.data.object.payment_intent
        @payment = ResourcePayment.where(pay_with_invoice: false, payment_intent: payment_intent).last
      end

      def call
        if payment.nil?
          invalid_payment_log('charge.refunded')
          return
        end

        payment.update(
          status: :refunded,
          status_time: status_time
        )
      end

      private

      def status_time
        Time.at(event.data.object.refunds.data.first.created.to_i)
      rescue StandardError
        log_status_time_error('charge.refunded')
        Time.current
      end

      def log_status_time_error(action)
        Rails.logger.error("Stripe - #{action} - Could not get status_time for payment_intent #{payment_intent}.")
      end

      def invalid_payment_log(action)
        Rails.logger.warn("Stripe - #{action} - No payment record for payment_intent #{payment_intent}.")
      end
    end
  end
end

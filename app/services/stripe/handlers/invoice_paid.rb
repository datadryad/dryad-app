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
          paid_at: paid_at(invoice),
          status_time: paid_at(invoice)
        )
        CurationService.new(resource: payment.resource, user_id: 0, status: 'queued', note: 'Invoice has been paid').process
      end
    end
  end
end

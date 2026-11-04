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
        update_last_invoice_size
        CurationService.new(resource: payment.resource, user_id: 0, status: new_status, note: 'Invoice has been paid').process
      end

      private

      def new_status
        resource = payment.resource.reload
        return 'queued' if resource.current_curation_status == 'awaiting_payment'

        resource.current_curation_status
      end

      def update_last_invoice_size
        ds_size = payment.resource.total_file_size || 0
        ident = payment.resource.identifier

        ident.update(last_invoiced_file_size: ds_size) if ident.last_invoiced_file_size.to_i < ds_size
      end
    end
  end
end

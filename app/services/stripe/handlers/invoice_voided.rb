module Stripe
  module Handlers
    class InvoiceVoided < InvoiceBase

      def call
        if payment.nil?
          invalid_payment_log('invoice.voided')
          return
        end

        if invoice.latest_revision
          update_payment(invoice.latest_revision)
        else
          payment.update(status: :voided, status_time: voided_at(invoice))
        end
      end

      def update_payment(new_invoice_id)
        if new_invoice_id
          stripe_invoice = Stripe::Invoice.retrieve(new_invoice_id)
          if stripe_invoice.latest_revision.present?
            update_payment(stripe_invoice.latest_revision)
            return
          end
        end

        updates = { invoice_id: new_invoice_id }
        case stripe_invoice.status
        when 'void'
          updates.merge!(status: :voided, status_time: voided_at(stripe_invoice), paid_at: nil)
        when 'paid'
          updates.merge!(status: :voided, status_time: paid_at(stripe_invoice), paid_at: paid_at(stripe_invoice))
        else
          updates.merge!(status: :created, paid_at: nil)
        end
        payment.update(updates)
      end
    end
  end
end

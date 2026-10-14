# :nocov:
namespace :payments do
  desc 'Check for voided invoices'
  task check_voided_invoices: :environment do
    last_invoice_id = nil
    loop do
      invoices = Stripe::Invoice.list({ status: 'void', starting_after: last_invoice_id, limit: 100 })
      last_invoice_id = void_invoices(invoices.data)
      break unless invoices.has_more
    end
  end

  desc 'Check for refunded transactions'
  task check_refunded_transactions: :environment do
    last_id = nil
    loop do
      transactions = Stripe::Refund.list({ starting_after: last_id, limit: 100 })
      last_id = refund_transactions(transactions.data)
      break unless transactions.has_more
    end
  end

  desc 'Check for paid invoices'
  task check_paid_invoices: :environment do
    last_invoice_id = nil
    loop do
      invoices = Stripe::Invoice.list({ status: 'paid', starting_after: last_invoice_id, limit: 100 })
      last_invoice_id = pay_invoices(invoices.data)
      break unless invoices.has_more
    end
  end

  def void_invoices(invoices)
    processed_ids = ResourcePayment.where(status: :voided).pluck(:invoice_id)

    invoices.each do |invoice|
      next if processed_ids.include?(invoice.id)

      payment = ResourcePayment.find_by(invoice_id: invoice.id)
      if payment.present?
        puts "Updating payment for invoice #{invoice.id}"
        Stripe::Handlers::InvoiceVoided.new(invoice: invoice).call
      else
        puts "No payment found for invoice #{invoice.id}"
      end
    end
    invoices.last&.id
  end

  def refund_transactions(transactions)
    processed_ids = ResourcePayment.where(status: :refunded).pluck(:payment_intent)

    transactions.each do |transaction|
      next if processed_ids.include?(transaction.payment_intent)

      payment = ResourcePayment.find_by(payment_intent: transaction.payment_intent)
      if payment.present?
        puts "Updating payment for intent #{transaction.payment_intent}"
        payment.update(status: :refunded, status_time: Time.at(transaction.created.to_i))
      else
        puts "No payment found for intent #{transaction.payment_intent}"
      end
    end
    transactions.last&.id
  end

  def pay_invoices(invoices)
    processed_ids = ResourcePayment.paid.select(:invoice_id).distinct.pluck(:invoice_id).uniq

    invoices.each do |invoice|
      next if processed_ids.include?(invoice.id)

      payment = ResourcePayment.find_by(invoice_id: invoice.id)
      if payment.present?
        puts "Updating payment for invoice #{invoice.id}"
        payment.update(
          status: :paid,
          paid_at: paid_at(invoice),
          status_time: paid_at(invoice)
        )
      else
        puts "No payment found for invoice #{invoice.id}"
      end
    end
    invoices.last&.id
  end

  def paid_at(stripe_invoice)
    Time.at(stripe_invoice.status_transitions.paid_at.to_i)
  rescue StandardError
    Time.current
  end
end
# :nocov:

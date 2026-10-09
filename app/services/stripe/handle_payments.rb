module Stripe
  class HandlePayments
    attr_reader :payment, :resource, :identifier
    def initialize(payment)
      @payment = payment
      @resource = payment.resource
      @identifier = @resource.identifier
    end

    def mark_session_paid(session_id, paid_at: Time.current)
      # Do not overwrite payment info in case it is already paid
      return if payment.paid?

      payment.update(
        status: :paid,
        payment_checkout_session_id: session_id,
        paid_at: paid_at
      )
      update_identifier_files_size
      update_payment_details(stripe_session)
    end

    private

    def update_identifier_files_size
      resource = payment.resource
      identifier = resource.identifier
      return if payment.ppr_fee_paid?
      return if SponsoredPaymentsService.new(resource).loggable?

      resource.fee_record&.update(status: :receipt)
      identifier.update(last_invoiced_file_size: [identifier.last_invoiced_file_size.to_i, resource.total_file_size.to_i].max)
    end

    def update_payment_details(session_id)
      stripe_session = Stripe::Checkout::Session.retrieve(session_id)

      payment.update(
        payment_intent: stripe_session[:payment_intent],
        payment_status: stripe_session[:payment_status],
        payment_email: stripe_session[:customer_email] || stripe_session[:customer_details][:email]
      )
      Payments::Identifier.new(identifier.id).update_payment_details(payment)
    rescue StandardError => e
      Rails.logger.warn("Could not fetch payment details for resource #{resource.id}, error: #{e.message}")
    end
  end
end

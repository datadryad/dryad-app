class PaymentsController < ApplicationController
  helper StashEngine::ApplicationHelper
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController

  skip_before_action :verify_authenticity_token
  before_action :load_resource
  before_action :ajax_require_unsubmitted, only: :create

  layout 'stash_engine/application'

  def create
    Stripe.api_key = APP_CONFIG.payments.key
    Stripe.api_version = '2025-03-31.basil'

    payment_service = PaymentsService.new(current_user, @resource, create_params)

    begin
      attrs = payment_service.checkout_options.merge(
        {
          return_url: "#{callback_payments_url}?resource_id=#{@resource.id}&session_id={CHECKOUT_SESSION_ID}",
          customer_email: @resource.owner_author.author_email
        }
      )
      session = Stripe::Checkout::Session.create(attrs)
      resource_payment = @resource.payment || @resource.build_payment
      resource_payment.update(
        payment_type: 'stripe',
        pay_with_invoice: false,
        checkout_session_id: session.id,
        status: :created,
        amount: payment_service.total_amount,
        has_discount: payment_service.has_discount,
        ppr_fee_paid: payment_service.ppr_fee_paid
      )
    rescue StandardError => e
      render json: {
        error: e.message
      }, status: :unprocessable_entity and return
    end

    render json: { clientSecret: session.client_secret }
  end

  def callback
    payment = @resource.payment || @resource.build_payment

    # do not update if a resource is already paid
    #  - success page refresh
    return if payment.paid?

    identifier.update(last_invoiced_file_size: [identifier.last_invoiced_file_size.to_i, @resource.total_file_size].max) unless payment.ppr_fee_paid?

    payment.update(
      status: :paid,
      payment_checkout_session_id: params[:session_id],
      paid_at: Time.current
    )
    if payment.checkout_session_id != params[:session_id]
      Rails.logger.warn("Resource #{params[:resource_id]} received a payment for wrong checkout session #{params[:checkout_session_id]}")
    end

    begin
      session = Stripe::Checkout::Session.retrieve(params[:session_id])
      payment.update(
        payment_intent: session[:payment_intent],
        payment_status: session[:payment_status],
        payment_email: session[:customer_email] || session[:customer_details][:email]
      )
      identifier.update(payment_type: 'stripe', payment_id: payment.payment_id)
    rescue StandardError => e
      Rails.logger.warn("Could not fetch payment details for resource #{@resource.id}, error: #{e.message}")
    end
  end

  def reset_payment
    identifier = StashEngine::Identifier.find(params[:identifier_id])
    identifier.update(last_invoiced_file_size: nil, payment_type: 'unknown', payment_id: nil)
    payment = identifier.payments.last
    payment.void_invoice
    payment.destroy

    redirect_to activity_log_path(id: identifier.id), notice: 'Payment information was reset.'
  end

  private

  def load_resource
    @resource = StashEngine::Resource.find(params[:resource_id])
  end

  def identifier
    @identifier ||= @resource.identifier
  end

  def create_params
    attrs = params.permit(%i[resource_id generate_invoice pay_ppr_fee])
    attrs[:generate_invoice] = ActiveModel::Type::Boolean.new.cast(attrs[:generate_invoice]) if attrs.key?(:generate_invoice)
    attrs[:pay_ppr_fee] = ActiveModel::Type::Boolean.new.cast(attrs[:pay_ppr_fee]) if attrs.key?(:pay_ppr_fee)
    attrs.to_hash.with_indifferent_access
  end
end

class PaymentsController < ApplicationController
  helper StashEngine::ApplicationHelper
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController

  skip_before_action :verify_authenticity_token
  before_action :load_resource

  layout 'stash_engine/application'

  def create
    Stripe.api_key = APP_CONFIG.payments.key
    Stripe.api_version = '2019-02-11; custom_checkout_beta=v1;'

    @payment_service = PaymentsService.new(current_user, @resource, create_params)

    begin
      attrs = @payment_service.checkout_options.merge({
        return_url: "#{callback_payments_url}?resource_id=#{@resource.id}&session_id={CHECKOUT_SESSION_ID}"
      })
      session = Stripe::Checkout::Session.create(attrs)
      resource_payment = @resource.payment || @resource.build_payment
      resource_payment.update(
        payment_type: 'stripe',
        checkout_session_id: session.id,
        status: :created,
        amount: @payment_service.total_amount
      )
    rescue StandardError => e
      render json: {
        error: e.error.message
      }, status: :unprocessable_entity and return
    end

    render json: { clientSecret: session.client_secret }
  end

  def callback
    payment = @resource.payment
    if payment && payment.checkout_session_id == params[:checkout_session_id]
      payment.update(status: :paid)
    else
      Rails.logger.warn("Resource #{params[:resource_id]} received a payment for wrong checkout session #{params[:checkout_session_id]}")
    end

    # TODO: Trigger @resource submit
  end

  private

  def load_resource
    @resource = StashEngine::Resource.find(params[:resource_id])
  end

  def create_params
    attrs = params.permit(%i[resource_id generate_invoice])
    attrs[:generate_invoice] = ActiveModel::Type::Boolean.new.cast(attrs[:generate_invoice]) if attrs.key?(:generate_invoice)
    attrs.to_hash.with_indifferent_access
  end
end

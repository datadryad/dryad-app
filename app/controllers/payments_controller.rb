class PaymentsController < ApplicationController
  helper StashEngine::ApplicationHelper
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController

  skip_before_action :verify_authenticity_token

  layout 'stash_engine/application'

  def create
    Stripe.api_key = APP_CONFIG.payments.key
    Stripe.api_version = '2019-02-11; custom_checkout_beta=v1;'

    # TODO: following
    # 1. create a resource_payment_info table
    # 2. find or create resource_payment_info and store Strip checkout details

    resource = StashEngine::Resource.find(create_params[:resource_id])
    options = PaymentsService.new(current_user, resource, create_params).checkout_options

    begin
      attrs = options.merge({ return_url: "#{callback_payments_url}?session_id={CHECKOUT_SESSION_ID}" })
      session = Stripe::Checkout::Session.create(attrs)
    rescue StandardError => e
      render json: {
        error: e.error.message
      }, status: :unprocessable_entity and return
    end

    render json: { clientSecret: session.client_secret }
  end

  def callback
    # TODO: find resource_payment_info by params[:session_id] and update it based on the response
    pp params
  end

  def create_params
    attrs = params.permit(%i[resource_id generate_invoice])
    attrs[:generate_invoice] = ActiveModel::Type::Boolean.new.cast(attrs[:generate_invoice]) if attrs.key?(:generate_invoice)
    attrs.to_hash.with_indifferent_access
  end
end

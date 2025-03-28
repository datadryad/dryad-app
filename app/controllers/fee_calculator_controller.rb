class FeeCalculatorController < ApplicationController
  respond_to :json
  before_action :validate_payer_type

  def calculate_fee
    render json: {
      options: options,
      fees: FeeCalculatorService.new(params[:type]).calculate(options)
    }
  end

  def calculate_resource_fee
    resource = StashEngine::Resource.find(params[:id])

    render json: {
      options: resource_options,
      fees: FeeCalculatorService.new(params[:type]).calculate(resource_options, resource: resource)
    }
  end

  private

  def validate_payer_type
    type = params[:type]
    raise NotImplementedError, 'Invalid calculator selected.' if %w[institution publisher individual].exclude?(type)
  end

  def options
    send("#{params[:type]}_permit_params").to_hash.with_indifferent_access
  end

  def institution_permit_params
    attrs = params.permit(
      :low_middle_income_country,
      :dpc_tier, :service_tier, storage_usage: %w[0 1 2 3 4 5 6]
    )
    attrs[:low_middle_income_country] = ActiveModel::Type::Boolean.new.cast(attrs[:low_middle_income_country])
    attrs
  end

  def publisher_permit_params
    attrs = params.permit(:dpc_tier, :service_tier, :cover_storage_fee, storage_usage: %w[0 1 2 3 4 5 6])
    attrs[:cover_storage_fee] = ActiveModel::Type::Boolean.new.cast(attrs[:cover_storage_fee])
    attrs
  end

  def individual_permit_params
    attrs = params.permit(%i[storage_size generate_invoice])
    attrs[:generate_invoice] = ActiveModel::Type::Boolean.new.cast(attrs[:generate_invoice])
    attrs
  end

  def resource_options
    attrs = params.permit(%i[generate_invoice])
    attrs[:generate_invoice] = ActiveModel::Type::Boolean.new.cast(attrs[:generate_invoice]) if attrs.key?(:generate_invoice)
    attrs.to_hash.with_indifferent_access
  end
end

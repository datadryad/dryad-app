class FeeCalculatorController < ApplicationController
  respond_to :json

  def calculate_fee
    calculate
  end

  def calculate_resource_fee
    resource = StashEngine::Resource.find(params[:id])

    calculate(resource: resource)
  end

  private

  def calculate(resource: nil)
    type = params[:type]
    raise NotImplementedError, 'Invalid calculator selected.' if %w[institution publisher individual].exclude?(type)

    render json: {
      options: options,
      fees: FeeCalculatorService.new(type).calculate(options, resource: resource)
    }
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
    attrs = params.permit(%i[storage_size generate_invoice type id])
    attrs[:generate_invoice] = ActiveModel::Type::Boolean.new.cast(attrs[:generate_invoice])
    attrs
  end
end

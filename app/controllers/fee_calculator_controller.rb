class FeeCalculatorController < ApplicationController
  respond_to :json

  def calculate_fee
    type = params[:type]
    if %w[institution publisher individual].exclude?(type)
      raise NotImplementedError, 'Invalid calculator selected.' if request.xhr?

      raise ActionController::RoutingError, 'Not Found'
    end

    render json: {
      options: options,
      fees: FeeCalculatorService.new(type).calculate(options)
    }
  end

  def calculate_resource_fee
    resource = StashEngine::Resource.find(params[:id])

    render json: {
      options: resource_options,
      fees: ResourceFeeCalculatorService.new(resource).calculate(resource_options)
    }
  end

  private

  def options
    send("#{params[:type]}_permit_params").to_hash.with_indifferent_access
  end

  def institution_permit_params
    attrs = params.permit(
      :low_middle_income_country, :cover_storage_fee,
      :dpc_tier, :service_tier, storage_usage: %w[0 1 2 3 4 5 6]
    )
    if attrs.key?(:low_middle_income_country)
      attrs[:low_middle_income_country] =
        ActiveModel::Type::Boolean.new.cast(attrs[:low_middle_income_country])
    end
    attrs[:cover_storage_fee] = ActiveModel::Type::Boolean.new.cast(attrs[:cover_storage_fee]) if attrs.key?(:cover_storage_fee)
    attrs
  end

  def publisher_permit_params
    attrs = params.permit(:dpc_tier, :service_tier, :cover_storage_fee, storage_usage: %w[0 1 2 3 4 5 6])
    attrs[:cover_storage_fee] = ActiveModel::Type::Boolean.new.cast(attrs[:cover_storage_fee]) if attrs.key?(:cover_storage_fee)
    attrs
  end

  def individual_permit_params
    attrs = params.permit(%i[storage_size generate_invoice pay_ppr_fee])
    attrs[:generate_invoice] = ActiveModel::Type::Boolean.new.cast(attrs[:generate_invoice]) if attrs.key?(:generate_invoice)
    attrs[:pay_ppr_fee] = ActiveModel::Type::Boolean.new.cast(attrs[:pay_ppr_fee]) if attrs.key?(:pay_ppr_fee)
    attrs
  end

  def resource_options
    attrs = params.permit(%i[id generate_invoice pay_ppr_fee])
    attrs[:generate_invoice] = ActiveModel::Type::Boolean.new.cast(attrs[:generate_invoice]) if attrs.key?(:generate_invoice)
    attrs[:pay_ppr_fee] = ActiveModel::Type::Boolean.new.cast(attrs[:pay_ppr_fee]) if attrs.key?(:pay_ppr_fee)
    attrs.to_hash.with_indifferent_access
  end
end

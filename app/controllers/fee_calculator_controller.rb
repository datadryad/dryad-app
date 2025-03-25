class FeeCalculatorController < ApplicationController

  respond_to :json
  def calculate_fee
    fee = calculate
    render json: {options: , value: fee}
  end

  def calculate_dataset_fee
    fee = calculate(dataset_fee: true)
    render json: {options: , value: fee}
  end

  private

  def calculate(dataset_fee: false)
    type = params[:type]
    FeeCalculatorService.new(type).calculate(options, for_dataset: dataset_fee)
  end

  def options
    params.permit(:type, :low_middle_income_country, :dpc, :service_fee, :storage_tier, :storage_size)
  end
end

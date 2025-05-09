class PaymentsService
  include StashEngine::ApplicationHelper

  attr_reader :user, :resource, :options

  def initialize(user, resource, options)
    @user = user
    @resource = resource
    @options = options
    @fees = ResourceFeeCalculatorService.new(resource).calculate(options)
    @storage_fee_label = @fees.delete(:storage_fee_label)
  end

  def checkout_options
    {
      mode: 'payment',
      ui_mode: 'embedded',
      line_items: line_items
    }
  end

  def total_amount
    @fees[:total]
  end

  private

  def line_items
    @fees.except(:total)
      .reject { |_k, v| v.zero? }
      .map { |key, value| generate_line_item(key, value) }
  end

  def generate_line_item(fee_key, value)
    {
      quantity: 1,
      price_data: {
        currency: 'usd',
        product_data: {
          name: product_name(fee_key)
        },
        unit_amount: value * 100 # Convert to cents
      }
    }
  end

  def product_name(fee_key)
    name = fee_key == :storage_fee ? @storage_fee_label : PRODUCT_NAME_MAPPER[fee_key]
    "#{name} for #{resource.identifier} (#{filesize(resource.total_file_size)})"
  end
end

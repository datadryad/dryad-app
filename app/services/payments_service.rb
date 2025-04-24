class PaymentsService
  attr_reader :user, :resource, :options

  def initialize(user, resource, options)
    @user = user
    @resource = resource
    @options = options
    @fees = ResourceFeeCalculatorService.new(resource).calculate(options)
    @fees = @fees.except(:storage_fee_label)
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
    @fees.except(:total).map { |key, value| generate_line_item(key, value) }
  end

  def generate_line_item(fee_key, value)
    {
      quantity: 1,
      price_data: {
        currency: 'usd',
        product_data: {
          name: PRODUCT_NAME_MAPPER[fee_key]
        },
        unit_amount: value * 100 # Convert to cents
      }
    }
  end
end

class PaymentsService
  include StashEngine::ApplicationHelper

  attr_reader :user, :resource, :options, :has_discount, :ppr_fee_paid

  def initialize(user, resource, options)
    @user = user
    @resource = resource
    @options = options
    @has_discount = false
    @ppr_fee_paid = false
    @fees = ResourceFeeCalculatorService.new(resource).calculate(options)
    process_options
  end

  def checkout_options
    res = {
      mode: 'payment',
      ui_mode: 'embedded',
      line_items: line_items
    }
    res[:discounts] = discounts if discounts.any?
    res
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
    "#{name} for #{resource.identifier} (#{filesize(resource.total_file_size)}) submitted by #{resource.submitter.name}"
  end

  def discounts
    return [] if @coupon_id.blank?

    [{ coupon: @coupon_id.to_s }]
  end

  def process_options
    @storage_fee_label = @fees.delete(:storage_fee_label)
    @coupon_id = @fees.delete(:coupon_id)
    @ppr_fee_paid = true if @fees.key?(:ppr_fee)
    @has_discount = true if @coupon_id.present?
    @fees.delete_if { |_, value| value.negative? }
  end
end

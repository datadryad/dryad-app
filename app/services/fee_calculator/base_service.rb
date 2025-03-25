module FeeCalculator
  class BaseService
    attr_reader :options, :for_dataset

    def initialize(options, for_dataset: false)
      @sum = 0
      @options = options
      @sum_options = {}
      @for_dataset = for_dataset
    end

    private

    def add_zero_fee(value_key)
      @sum_options[value_key] = 0
    end

    def add_fee_by_tier(tier_definition, value_key)
      value = price_by_tier(tier_definition, options[value_key])
      @sum += value
      @sum_options[value_key] = value
    end

    def price_by_tier(tier_definition, value)
      tier = tier_definition.find { |t| t[:tier] == value.to_i }
      tier ? tier[:price] : 0
    end

    def add_fee_by_range(tier_definition, value_key)
      value = price_by_range(tier_definition, options[value_key])
      @sum += value
      @sum_options[value_key] = value
    end

    def price_by_range(tier_definition, value)
      tier = tier_definition.find { |t| t[:range].include?(value.to_i) }
      tier ? tier[:price] : 0
    end
  end
end

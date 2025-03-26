module FeeCalculator
  class BaseService
    attr_reader :options, :for_dataset

    def initialize(options, for_dataset: false)
      @sum = 0
      @options = options
      @sum_options = {}
      @for_dataset = for_dataset
    end

    def call
      if for_dataset
        add_zero_fee(:service_fee)
        add_zero_fee(:dpc)
        add_storage_fee
      else
        add_service_fee
        add_dpc_fee
        add_storage_usage_fees
      end
      @sum_options.merge(total: @sum)
    end

    private

    def add_zero_fee(value_key)
      @sum_options[value_key] = 0
    end

    def add_dpc_fee
      add_fee_by_tier(dpc_fee_tiers, :dpc_tier)
    end

    def add_service_fee
      add_fee_by_tier(service_fee_tiers, :service_tier)
    end

    def add_storage_usage_fees
      return unless options[:storage_usage]

      res = {}
      options[:storage_usage].each do |tier, percent|
        datasets = get_tier_by_value(dpc_fee_tiers, options[:dpc_tier])
        items = (datasets[:range].max * percent.to_i / 100.0).round
        items_fee = items * price_by_tier(storage_fee_tiers, tier)
        res[tier] = items_fee
        @sum += items_fee
      end
      @sum_options[:storage_by_tier] = res
    end

    def add_storage_usage_fee(key)
      add_fee_by_range(storage_fee_tiers, key)
    end

    def add_storage_fee
      add_fee_by_range(storage_fee_tiers, :storage_size)
    end

    def add_fee_by_tier(tier_definition, value_key)
      value = price_by_tier(tier_definition, options[value_key])
      @sum += value
      @sum_options[output_key(value_key)] = value
    end

    def output_key(key)
      key.to_s.gsub('_tier', '_fee').gsub('_size', '_fee').to_sym
    end

    def price_by_tier(tier_definition, value)
      tier = get_tier_by_value(tier_definition, value)
      tier[:price].to_i
    end

    # if tier is not matched, consider first tier
    def get_tier_by_value(tier_definition, value)
      tier = tier_definition.find { |t| t[:tier] == value.to_i }
      tier || tier_definition.find { |t| t[:tier] == 1 }
    end

    def add_fee_by_range(tier_definition, value_key)
      value = price_by_range(tier_definition, options[value_key])
      @sum += value
      @sum_options[output_key(value_key)] = value
    end

    def price_by_range(tier_definition, value)
      tier = tier_definition.find { |t| t[:range].include?(value.to_i) }
      tier ? tier[:price] : 0
    end
  end
end

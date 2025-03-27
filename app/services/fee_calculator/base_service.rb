module FeeCalculator
  class BaseService
    attr_reader :options, :for_dataset

    # rubocop:disable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing
    ESTIMATED_DATASETS = [
      { tier:  1, range:   0..  5, price:      0 },
      { tier:  2, range:   6.. 15, price:  1_650 },
      { tier:  3, range:  16.. 25, price:  2_700 },
      { tier:  4, range:  26.. 50, price:  5_350 },
      { tier:  5, range:  51.. 75, price:  7_950 },
      { tier:  6, range:  76..100, price: 10_500 },
      { tier:  7, range: 101..150, price: 15_600 },
      { tier:  8, range: 151..200, price: 20_500 },
      { tier:  9, range: 201..250, price: 25_500 },
      { tier: 10, range: 251..300, price: 30_250 },
      { tier: 11, range: 301..350, price: 35_000 },
      { tier: 12, range: 351..400, price: 39_500 },
      { tier: 13, range: 401..450, price: 44_000 },
      { tier: 14, range: 451..500, price: 48_750 },
      { tier: 15, range: 501..550, price: 53_500 },
      { tier: 16, range: 551..600, price: 58_250 }
    ].freeze

    ESTIMATED_FILES_SIZE = [
      { tier: 1, range:    10_000_000_000..   50_000_000_000, price:   259 },
      { tier: 2, range:    50_000_000_001..  100_000_000_000, price:   464 },
      { tier: 3, range:   100_000_000_001..  250_000_000_000, price: 1_123 },
      { tier: 4, range:   250_000_000_001..  500_000_000_000, price: 2_153 },
      { tier: 5, range:   500_000_000_001..1_000_000_000_000, price: 4_347 },
      { tier: 6, range: 1_000_000_000_001..2_000_000_000_000, price: 8_809 }
    ].freeze
    # rubocop:enable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing

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
      raise ActionController::BadRequest, 'The value is out of defined range' if tier.nil?

      tier[:price]
    end
  end
end

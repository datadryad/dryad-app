module FeeCalculator
  class BaseService
    attr_reader :options, :resource

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
      { tier: 0, range:                 0..   10_000_000_000, price:     0 },
      { tier: 1, range:    10_000_000_001..   50_000_000_000, price:   259 },
      { tier: 2, range:    50_000_000_001..  100_000_000_000, price:   464 },
      { tier: 3, range:   100_000_000_001..  250_000_000_000, price: 1_123 },
      { tier: 4, range:   250_000_000_001..  500_000_000_000, price: 2_153 },
      { tier: 5, range:   500_000_000_001..1_000_000_000_000, price: 4_347 }
      # { tier: 6, range: 1_000_000_000_001..2_000_000_000_000, price: 8_809 }
    ].freeze

    INVOICE_FEE = 199
    # rubocop:enable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing

    def initialize(options = {}, resource: nil)
      @sum = 0
      @options = options
      @sum_options = {}
      @resource = resource
      @payer = resource ? resource.identifier.payer : nil
      @payment_plan_is_2025 = resource ? resource.identifier.payer_2025? : false
      @covers_ldf = resource ? resource.identifier.payer&.covers_ldf : false
    end

    def call
      verify_payer
      verify_new_payment_system

      if resource.present?
        add_zero_fee(:service_tier)
        add_zero_fee(:dpc_tier)
        if @covers_ldf
          verify_max_storage_size
          add_zero_fee(:storage_size)
        else
          add_storage_fee_difference
          add_invoice_fee
        end
      else
        add_service_fee
        add_dpc_fee
        add_storage_usage_fees
      end
      add_storage_fee_label
      @sum_options.merge(total: @sum)
    end

    def storage_fee_tiers
      ESTIMATED_FILES_SIZE
    end

    def dpc_fee_tiers
      ESTIMATED_DATASETS
    end

    private

    def verify_new_payment_system
      raise ActionController::BadRequest, OLD_PAYMENT_SYSTEM_MESSAGE if resource && !@payment_plan_is_2025
    end

    def verify_payer
      raise ActionController::BadRequest, MISSING_PAYER_MESSAGE if resource && !@payer
    end

    def add_zero_fee(value_key)
      add_fee_to_total(value_key, 0)
    end

    def add_invoice_fee
      return unless options[:generate_invoice]
      return if @sum.zero?

      @sum += INVOICE_FEE
      @sum_options[:invoice_fee] = INVOICE_FEE
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
        items = (datasets[:range].max * percent.to_i / 100.0).ceil
        items_fee = items * price_by_tier(storage_fee_tiers, tier)
        res[tier] = items_fee
        @sum += items_fee if options[:cover_storage_fee]
      end
      @sum_options[:storage_by_tier] = res
    end

    def add_storage_fee_difference(paid_storage_size = nil)
      paid_storage_size ||= resource.identifier.previous_invoiced_file_size
      paid_tier_price = price_by_range(storage_fee_tiers, paid_storage_size)
      new_tier_price = price_by_range(storage_fee_tiers, resource.total_file_size)

      diff = new_tier_price - paid_tier_price
      diff = 0 if diff < 0

      add_fee_to_total(:storage_size, diff)
    end

    def verify_max_storage_size
      price_by_range(storage_fee_tiers, resource.total_file_size)
    end

    def add_storage_usage_fee(key)
      add_fee_by_range(storage_fee_tiers, key)
    end

    def add_storage_fee
      add_fee_by_range(storage_fee_tiers, :storage_size)
    end

    def add_dataset_storage_fee
      price = price_by_range(storage_fee_tiers, resource.total_file_size)
      add_fee_to_total(:storage_size, price)
    end

    def add_fee_by_tier(tier_definition, value_key)
      value = price_by_tier(tier_definition, options[value_key])
      add_fee_to_total(value_key, value)
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
      add_fee_to_total(value_key, value)
    end

    def price_by_range(tier_definition, value)
      tier = tier_definition.find { |t| t[:range].include?(value.to_i) }
      raise ActionController::BadRequest, OUT_OF_RANGE_MESSAGE if tier.nil?

      tier[:price]
    end

    def add_fee_to_total(value_key, fee)
      @sum += fee
      @sum_options[output_key(value_key)] = fee
    end

    def add_storage_fee_label
      @sum_options[:storage_fee_label] = storage_fee_label
    end

    def storage_fee_label
      PRODUCT_NAME_MAPPER[:storage_fee]
    end

    def add_storage_discount_fee(value_key, storage_size)
      value = price_by_range(storage_fee_tiers, storage_size)
      add_fee_to_total(value_key, -value)
    end

    def add_coupon(coupon_id)
      @sum_options[:coupon_id] = coupon_id
    end
  end
end

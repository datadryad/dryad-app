module FeeCalculator
  class BaseService
    attr_reader :options, :resource

    def initialize(options = {}, resource: nil, payer_record: nil)
      @sum = 0
      @options = options
      @sum_options = {}
      @resource = resource
      @payer = payer_record || (resource ? resource.identifier.payer : nil)
      @payer = PayersService.new(@payer).payment_sponsor if @payer
      @payment_plan_is_2025 = resource ? resource.identifier.payer_2025?(@payer) : false
      @covers_ldf = resource ? @payer&.payment_configuration&.covers_ldf : false
      @ldf_limit = resource ? @payer&.payment_configuration&.ldf_limit : nil
    end

    def call
      verify_payer
      verify_new_payment_system

      if resource.present?
        add_zero_fee(:service_tier)
        add_zero_fee(:dpc_tier)
        limits_service = PaymentLimitsService.new(resource, @payer, ldf_sponsored_amount: ldf_sponsored_amount)

        if @covers_ldf
          @sum_options[:storage_fee_label] = PRODUCT_NAME_MAPPER[:storage_fee_overage] unless @ldf_limit.nil?
          if @ldf_limit.nil? && limits_service.payment_allowed?
            # if no limit is hit,
            # the user pays no storage fee
            verify_max_storage_size
            add_zero_fee(:storage_size)
          elsif limits_service.amount_limits_exceeded?
            # if the yearly amount limit is hit,
            # the user needs to pay the full storage difference
            add_storage_fee_difference
            add_invoice_fee
          else
            # if the amount by adding sponsored storage fee is not exceeded
            # user mult pay the difference between sponsored size and resource size
            handle_ldf_limit
          end
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

    def handle_ldf_limit
      @sum_options[:storage_fee_label] = PRODUCT_NAME_MAPPER[:storage_fee_overage]
      tier = get_tier_by_value(storage_fee_tiers, @ldf_limit)
      paid_for = [tier[:range].max, resource.identifier.last_invoiced_file_size.to_i].max

      add_storage_fee_difference(paid_for)
      add_invoice_fee
    end

    def ldf_sponsored_amount(paid_storage_size: nil)
      paid_storage_size ||= resource.identifier.last_invoiced_file_size.to_i
      paid_tier_price = price_by_range(storage_fee_tiers, paid_storage_size)

      new_tier_price = price_by_range(storage_fee_tiers, resource.total_file_size)

      diff = [new_tier_price - paid_tier_price, 0].max
      return diff if diff.zero?
      return diff if !@payment_plan_is_2025 || !@covers_ldf

      sponsored_price = 0
      if @ldf_limit.present?
        sponsored_tier = get_tier_by_value(storage_fee_tiers, @ldf_limit)
        sponsored_price = sponsored_tier[:price]
      end

      [diff, sponsored_price].min
    end

    def storage_fee_tier
      get_tier_by_range(storage_fee_tiers, resource.total_file_size)
    end

    # if tier is not matched, consider first tier
    def get_tier_by_value(tier_definition, value)
      tier = tier_definition.find { |t| t[:tier] == value.to_i }
      tier || tier_definition.find { |t| t[:tier] == 1 }
    end

    private

    def verify_new_payment_system
      return if resource.blank? || (@payment_plan_is_2025 && !resource.identifier.old_payment_system?)
      return if @payer && !resource.identifier.old_system_valid_payer?

      raise ActionController::BadRequest, OLD_PAYMENT_SYSTEM_MESSAGE
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

    def add_ppr_fee(ppr_fee)
      return unless options[:pay_ppr_fee]
      return if @sum.zero?

      # replace existing sum
      @sum = ppr_fee
      @sum_options.delete(:storage_fee)
      @sum_options[:ppr_fee] = ppr_fee
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
      paid_storage_size ||= resource.identifier.last_invoiced_file_size
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

    def add_fee_by_range(tier_definition, value_key)
      value = price_by_range(tier_definition, options[value_key])
      add_fee_to_total(value_key, value)
    end

    def price_by_range(tier_definition, value)
      tier = tier_definition.find { |t| t[:range].include?(value.to_i) }
      raise ActionController::BadRequest, OUT_OF_RANGE_MESSAGE if tier.nil?

      tier[:price]
    end

    def get_tier_by_range(tier_definition, value)
      tier = tier_definition.find { |t| t[:range].include?(value.to_i) }
      raise ActionController::BadRequest, OUT_OF_RANGE_MESSAGE if tier.nil?

      tier
    end

    def add_fee_to_total(value_key, fee)
      @sum += fee
      @sum_options[output_key(value_key)] = fee
    end

    def add_storage_fee_label
      @sum_options[:storage_fee_label] ||= storage_fee_label
    end

    def storage_fee_label
      PRODUCT_NAME_MAPPER[:storage_fee]
    end

    def add_storage_discount_fee(value_key, storage_size)
      value = price_by_range(storage_fee_tiers, storage_size)
      value = [value, @sum].min
      add_fee_to_total(value_key, -value)
    end

    def add_coupon(coupon_id)
      @sum_options[:coupon_id] = coupon_id
    end
  end
end

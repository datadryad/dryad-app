module FeeCalculator
  class IndividualService < BaseService
    # rubocop:disable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing
    INDIVIDUAL_ESTIMATED_FILES_SIZE = [
      { tier: 1, range:                 0..    5_000_000_000, price:    150 },
      { tier: 2, range:     5_000_000_001..   10_000_000_000, price:    180 },
      { tier: 3, range:    10_000_000_001..   50_000_000_000, price:    520 },
      { tier: 4, range:    50_000_000_001..  100_000_000_000, price:    808 },
      { tier: 5, range:   100_000_000_001..  250_000_000_000, price:  1_750 },
      { tier: 6, range:   250_000_000_001..  500_000_000_000, price:  3_086 },
      { tier: 7, range:   500_000_000_001..1_000_000_000_000, price:  6_077 },
      { tier: 8, range: 1_000_000_000_001..2_000_000_000_000, price: 12_162 }
    ].freeze

    PPR_FEE = 50
    PPR_COUPON_ID = 'PPR_DISCOUNT_2025'.freeze
    # rubocop:enable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing

    def call
      verify_new_payment_system
      verify_max_storage_size if resource

      add_individual_storage_fee
      add_storage_fee_label
      add_ppr_fee(PPR_FEE)
      add_invoice_fee
      add_ppr_discount
      @sum_options.merge(total: @sum)
    end

    def storage_fee_tiers
      INDIVIDUAL_ESTIMATED_FILES_SIZE
    end

    private

    def storage_fee_label
      PRODUCT_NAME_MAPPER[:individual_storage_fee]
    end

    def add_individual_storage_fee
      if resource.present?
        if resource.identifier.last_invoiced_file_size.nil?
          add_dataset_storage_fee
        else
          add_storage_fee_difference
        end
      else
        add_storage_fee
      end
    end

    def add_ppr_discount
      return if @sum.zero?
      return unless resource.present?
      return unless resource.identifier.payments.ppr_paid.where.not(resource_id: resource.id).first&.amount == PPR_FEE
      return unless resource.identifier.payments.with_discount.where.not(resource_id: resource.id).count.zero?

      add_fee_to_total(:ppr_discount, -PPR_FEE)
      add_coupon(PPR_COUPON_ID)
    end
  end
end

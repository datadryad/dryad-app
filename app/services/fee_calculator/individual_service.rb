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
    # rubocop:enable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing

    def call
      if resource.present? && resource.previously_published?
        add_storage_fee_difference
        add_invoice_fee
      else
        add_storage_fee
        add_invoice_fee
      end
      @sum_options.merge(total: @sum)
    end

    private

    def storage_fee_tiers
      INDIVIDUAL_ESTIMATED_FILES_SIZE
    end
  end
end

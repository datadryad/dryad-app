module FeeCalculator
  class InstitutionService < BaseService
    # rubocop:disable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing
    NORMAL_SERVICE_FEE = [
      { tier: 1, range:             0..     99_000_000, price:  5_000 },
      { tier: 2, range:   100_000_001..    250_000_000, price: 10_000 },
      { tier: 3, range:   250_000_001..    500_000_000, price: 20_000 },
      { tier: 4, range:   500_000_001..    750_000_000, price: 30_000 },
      { tier: 5, range:   750_000_001..  1_000_000_000, price: 40_000 },
      { tier: 6, range: 1_000_000_001..Float::INFINITY, price: 50_000 }
    ].freeze

    LOW_MIDDLE_SERVICE_FEE = [
      { tier: 1, range:           0..      5_000_000, price: 1_000 },
      { tier: 2, range:   5_000_001..     25_000_000, price: 1_500 },
      { tier: 3, range:  25_000_001..     50_000_000, price: 2_500 },
      { tier: 4, range:  50_000_001..    100_000_000, price: 5_000 },
      { tier: 5, range: 100_000_001..Float::INFINITY, price: 7_500 }
    ].freeze
    # rubocop:enable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing

    def service_fee_tiers
      return LOW_MIDDLE_SERVICE_FEE if options[:low_middle_income_country]

      NORMAL_SERVICE_FEE
    end

    def storage_fee_tiers
      ESTIMATED_FILES_SIZE
    end

    def dpc_fee_tiers
      ESTIMATED_DATASETS
    end
  end
end

module FeeCalculator
  class PublisherService < BaseService
    # rubocop:disable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing
    SERVICE_FEE = [
      { tier:  1, range:           0..        500_000, price:  1_000 },
      { tier:  2, range:     500_001..      1_000_000, price:  2_500 },
      { tier:  3, range:   1_000_001..      5_000_000, price:  5_000 },
      { tier:  4, range:   5_000_001..     10_000_000, price:  7_500 },
      { tier:  5, range:  10_000_001..     25_000_000, price: 10_000 },
      { tier:  6, range:  25_000_001..     50_000_000, price: 12_500 },
      { tier:  7, range:  50_000_001..    100_000_000, price: 15_000 },
      { tier:  8, range: 100_000_001..    200_000_000, price: 22_500 },
      { tier:  9, range: 200_000_001..    500_000_000, price: 30_000 },
      { tier: 10, range: 500_000_001..Float::INFINITY, price: 40_000 }
    ].freeze

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

    private

    def service_fee_tiers
      SERVICE_FEE
    end

    def add_storage_usage_fees
      return unless options[:cover_storage_fee]

      super
    end

    def storage_fee_tiers
      ESTIMATED_FILES_SIZE
    end

    def dpc_fee_tiers
      ESTIMATED_DATASETS
    end
  end
end

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
    # rubocop:enable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing

    def service_fee_tiers
      SERVICE_FEE
    end
  end
end

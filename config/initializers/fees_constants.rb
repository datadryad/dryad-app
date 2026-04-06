# frozen_string_literal: true

# New payment system error messages
OLD_PAYMENT_SYSTEM_MESSAGE = 'Payer is not on 2025 payment plan'.freeze
MISSING_PAYER_MESSAGE = 'Payer is missing. Please use individual calculator.'.freeze
OUT_OF_RANGE_MESSAGE = 'The value is out of defined range'.freeze

INVOICE_FEE = 199
PPR_FEE = 50
PPR_COUPON_ID = 'PPR_DISCOUNT_2025'.freeze

# Waiver
DISCOUNT_STORAGE_COUPON_ID = 'FEE_WAIVER_2025'.freeze
FREE_STORAGE_SIZE = 10_000_000_000 # 10 GB

# rubocop:disable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing
INDIVIDUAL_ESTIMATED_FILES_SIZE = if Rails.env.development? || Rails.env.dev?
  # Values in MB
  [
    { tier: 1, range:             0..    5_000_000, price:    150 },
    { tier: 2, range:     5_000_001..   10_000_000, price:    180 },
    { tier: 3, range:    10_000_001..   50_000_000, price:    520 },
    { tier: 4, range:    50_000_001..  100_000_000, price:    808 },
    { tier: 5, range:   100_000_001..  250_000_000, price:  1_750 },
    { tier: 6, range:   250_000_001..  500_000_000, price:  3_086 },
    { tier: 7, range:   500_000_001..1_000_000_000, price:  6_077 },
    { tier: 8, range: 1_000_000_001..2_000_000_000, price: 12_162 }
  ].freeze
else
  # Values in GB
  [
    { tier: 1, range:                 0..    5_000_000_000, price:    150 },
    { tier: 2, range:     5_000_000_001..   10_000_000_000, price:    180 },
    { tier: 3, range:    10_000_000_001..   50_000_000_000, price:    520 },
    { tier: 4, range:    50_000_000_001..  100_000_000_000, price:    808 },
    { tier: 5, range:   100_000_000_001..  250_000_000_000, price:  1_750 },
    { tier: 6, range:   250_000_000_001..  500_000_000_000, price:  3_086 },
    { tier: 7, range:   500_000_000_001..1_000_000_000_000, price:  6_077 },
    { tier: 8, range: 1_000_000_000_001..2_000_000_000_000, price: 12_162 }
  ].freeze
end

ESTIMATED_FILES_SIZE = if Rails.env.development? || Rails.env.dev?
  # Values in MB
  [
    { tier: 0, range:             0..   10_000_000, price:     0 },
    { tier: 1, range:    10_000_001..   50_000_000, price:   259 },
    { tier: 2, range:    50_000_001..  100_000_000, price:   464 },
    { tier: 3, range:   100_000_001..  250_000_000, price: 1_123 },
    { tier: 4, range:   250_000_001..  500_000_000, price: 2_153 },
    { tier: 5, range:   500_000_001..1_000_000_000, price: 4_347 },
    { tier: 6, range: 1_000_000_001..2_000_000_000, price: 8_809 }
  ].freeze
else
  # Values in GB
  [
    { tier: 0, range:                 0..   10_000_000_000, price:     0 },
    { tier: 1, range:    10_000_000_001..   50_000_000_000, price:   259 },
    { tier: 2, range:    50_000_000_001..  100_000_000_000, price:   464 },
    { tier: 3, range:   100_000_000_001..  250_000_000_000, price: 1_123 },
    { tier: 4, range:   250_000_000_001..  500_000_000_000, price: 2_153 },
    { tier: 5, range:   500_000_000_001..1_000_000_000_000, price: 4_347 },
    { tier: 6, range: 1_000_000_000_001..2_000_000_000_000, price: 8_809 }
  ].freeze
  end

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
# rubocop:enable Layout/SpaceInsideRangeLiteral, Layout/ExtraSpacing

NORMAL_SERVICE_FEE = [
  { tier: 1, range:             0..    100_000_000, price:  5_000 },
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

PUBLISHER_SERVICE_FEE = [
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

# New fee calculator mapping keys to product names
PRODUCT_NAME_MAPPER = {
  service_fee: 'Annual service fee',
  dpc_fee: 'Datasets count fee',
  invoice_fee: 'Invoice fee',
  storage_fee: 'Large data fee',
  storage_fee_overage: 'Large data fee overage',
  individual_storage_fee: 'Data Publishing Charge',
  total: 'Total',
  waiver_discount: 'Fee waiver discount',
  ppr_fee: 'Private for Peer Review Fee',
  ppr_discount: 'Paid Private for Peer Review Fee'
}.freeze

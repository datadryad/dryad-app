# frozen_string_literal: true

DEFAULT_PAGE_SIZE = 20
REPORTS_DIR = 'reports'.freeze
EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i

# New fee calculator mapping keys to product names
PRODUCT_NAME_MAPPER = {
  service_fee: 'Annual service fee',
  dpc_fee: 'Datasets count fee',
  invoice_fee: 'Invoice fee',
  storage_fee: 'Large data fee',
  individual_storage_fee: 'Data Publishing Charge',
  total: 'Total',
  waiver_discount: 'Fee waiver discount',
}.freeze

# New payment system error messages
OLD_PAYMENT_SYSTEM_MESSAGE = 'Payer is not on 2025 payment plan'.freeze
MISSING_PAYER_MESSAGE = 'Payer is missing. Please use individual calculator.'.freeze
OUT_OF_RANGE_MESSAGE = 'The value is out of defined range'.freeze

SUBMISSION_QUEUE_NOTIFICATION_LIMIT = 10.freeze
SUBMISSION_QUEUE_NOTIFICATION_EVERY = 30.minutes.freeze

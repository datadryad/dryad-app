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
  total: 'Total'
}.freeze

OLD_PAYMENT_SYSTEM_MESSAGE = 'Payer is not on 2025 payment plan'.freeze

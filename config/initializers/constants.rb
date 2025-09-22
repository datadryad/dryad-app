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
  storage_fee_overage: 'Large data fee overage',
  individual_storage_fee: 'Data Publishing Charge',
  total: 'Total',
  waiver_discount: 'Fee waiver discount',
  ppr_fee: 'Private for Peer Review Fee',
  ppr_discount: 'Paid Private for Peer Review Fee'
}.freeze

# New payment system error messages
OLD_PAYMENT_SYSTEM_MESSAGE = 'Payer is not on 2025 payment plan'.freeze
MISSING_PAYER_MESSAGE = 'Payer is missing. Please use individual calculator.'.freeze
OUT_OF_RANGE_MESSAGE = 'The value is out of defined range'.freeze

SUBMISSION_QUEUE_NOTIFICATION_LIMIT = 10.freeze
SUBMISSION_QUEUE_NOTIFICATION_EVERY = 30.minutes.freeze

ROOT_URL = if Rails.application.default_url_options[:port].present?
  "http://#{Rails.application.default_url_options[:host]}:#{Rails.application.default_url_options[:port]}".freeze
else
  "https://#{Rails.application.default_url_options[:host]}".freeze
end

NIH_ROR = 'https://ror.org/01cwqze88'.freeze
NSF_ROR = 'https://ror.org/021nxhr62'.freeze

API_INTEGRATIONS = {
  'NIH' => NIH_ROR,
  'NSF' => NSF_ROR
}.freeze

NIH_GRANT_REGEX = /
  [0-9A-Za-z]?         # optional application type
  [A-Z]{1,2}\d{2,3}    # activity code
  [A-Z]{2}             # institute code
  \d{6}                # serial number
  (?:-\d{2}[A-Z0-9]*)? # optional year + suffix
/x

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

SUBMISSION_REDIS_KEY = 'resource:%{resource.id}:remaining_files'.freeze

HELP_PAGES_REQUIREMENTS =
  [
    { path: '/help/requirements/files', name: 'File requirements' },
    { path: '/help/requirements/metadata', name: 'Metadata requirements' },
    { path: '/help/requirements/costs', name: 'Costs' }
  ]

HELP_PAGES_GUIDES =
  [
    { path: '/help/guides/QuickstartGuideToDataSharing.pdf', name: 'Data sharing (quick start)' },
    { path: '/help/guides/best_practices', name: 'Good data practices' },
    { path: '/help/guides/reuse', name: 'How to reuse Dryad data' },
    { path: '/help/guides/EndangeredSpeciesData.pdf', name: 'Guidance for species data' },
    { path: '/help/guides/HumanSubjectsData.pdf', name: 'Sharing human subjects data' },
    { path: '/help/guides/data_check_alerts', name: 'Tabular data check alerts' }
  ]

HELP_PAGES_STEPS =
  [
    { path: '/help/submission_steps/submission', name: 'Submission walkthrough' },
    { path: '/help/submission_steps/curation', name: 'Dataset curation' },
    { path: '/help/submission_steps/publication', name: 'Published datasets' }
  ]

HELP_PAGES = HELP_PAGES_REQUIREMENTS + HELP_PAGES_GUIDES + HELP_PAGES_STEPS

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

HELP_PAGES_ACCOUNT = [
  { path: '/help/account/login', name: 'Creating a Dryad account'},
  { path: '/help/account/management', name: 'Managing my account'}
]

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

NIH_ROR_NAMES_MAPPING = {
  'agency for healthcare research and quality' => 'https://ror.org/03jmfdf59',
  'national cancer institute' => 'https://ror.org/040gcmg81',
  'national eye institute' => 'https://ror.org/03wkg3b53',
  'national heart lung and blood institute' => 'https://ror.org/012pb6c26',
  'national human genome research institute' => 'https://ror.org/00baak391',
  'national institute on aging' => 'https://ror.org/049v75w11',
  'national institute on alcohol abuse and alcoholism' => 'https://ror.org/02jzrsm59',
  'national institute of allergy and infectious diseases' => 'https://ror.org/043z4tv69',
  'national institute of arthritis and musculoskeletal and skin diseases' => 'https://ror.org/006zn3t30',
  'national institute of arthritits and musculoskeletal and skin diseases' => 'https://ror.org/006zn3t30',
  'national institute of biomedical imaging and bioengineering' => 'https://ror.org/00372qc85',
  'eunice kennedy shriver national institute of child health and human development' => 'https://ror.org/04byxyr05',
  'national institute on deafness and other communication disorders' => 'https://ror.org/04mhx6838',
  'national institute of dental and craniofacial research' => 'https://ror.org/004a2wv92',
  'national institute of diabetes and digestive and kidney diseases' => 'https://ror.org/00adh9b73',
  'national institute on drug abuse' => 'https://ror.org/00fq5cm18',
  'national institute of environmental health sciences' => 'https://ror.org/00j4k1h63',
  'national institute of general medical sciences' => 'https://ror.org/04q48ey07',
  'national institute of mental health' => 'https://ror.org/04xeg9z08',
  'national institute on minority health and health disparities' => 'https://ror.org/0493hgw16',
  'national institute of neurological disorders and stroke' => 'https://ror.org/01s5ya894',
  'national institute of nursing research' => 'https://ror.org/01y3zfr79',
  'national library of medicine' => 'https://ror.org/0060t0j89',
  'nih clinical center' => 'https://ror.org/04vfsmv21',
  'center for information technology' => 'https://ror.org/03jh5a977',
  'center for scientific review' => 'https://ror.org/04r5s4b52',
  'fogarty international center' => 'https://ror.org/02xey9a22',
  'john e. fogarty international center for advanced study in the health sciences' => 'https://ror.org/02xey9a22',
  'national center for advancing translational sciences' => 'https://ror.org/04pw6fb54',
  'national center for complementary and integrative health' => 'https://ror.org/00190t495',
  'national center for complementary and intergrative health' => 'https://ror.org/00190t495',
  'national center for emerging and zoonotic infectious diseases' => 'https://ror.org/02ggwpx62',
  'national institute for occupational safety and health' => 'https://ror.org/0502a2655',
  'national center for immunization and respiratory diseases' => 'https://ror.org/05je2tx78',
  'national center for injury prevention and control' => 'https://ror.org/0015x1k58',
  'nih office of the director' => 'https://ror.org/00fj8a872',
  'office of research infrastructure programs' => 'https://ror.org/01jdyfj45'
}.freeze

NSF_ROR_NAMES_MAPPING = {
  'division of molecular and cellular biosciences' => 'https://ror.org/002jdaq33',
  'office of emerging frontiers in research and innovation (efri)' => 'https://ror.org/0388pet74',
  'division of civil, mechanical, and manufacturing innovation' => 'https://ror.org/028yd4c30',
  'office of polar programs (opp)' => 'https://ror.org/05nwjp114',
  'division of information & intelligent systems' => 'https://ror.org/053a2cp42',
  # 'integrative and collaborative education and research (icer)' => '',
  'division of engineering education and centers' => 'https://ror.org/050rnw378',
  'div. of equity for excellence in stem' => 'https://ror.org/03mamvh39',
  'office of advanced cyberinfrastructure (oac)' => 'https://ror.org/04nh1dc89',
  'oia-office of integrative activities' => 'https://ror.org/04k9mqs78',
  'emerging frontiers' => 'https://ror.org/01tnvpc68'
}.freeze

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

HELP_PAGES = HELP_PAGES_REQUIREMENTS + HELP_PAGES_GUIDES + HELP_PAGES_STEPS + HELP_PAGES_ACCOUNT

SMALL_UPLOAD_QUEUE_LIMIT = 2_000_000_000 # 2 GB

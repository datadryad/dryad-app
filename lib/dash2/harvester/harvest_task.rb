# Class representing a single harvest operation.
#
# @!attribute [r] oai_base_uri
#   @return [URI] the base URL of the repository.
# @!attribute [r] from_time
#   @return [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
# @!attribute [r] until_time
#   @return [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
# @!attribute seconds_granularity [r]
#   @return [Boolean] whether to include the full time out to the second in the from / until time range. (Defaults to false, i.e., days granularity.)
# @!attribute [r] metadata_prefix
#   @return [String] the metadata prefix defining the metadata format requested from the repository.

class Dash2::Harvester::HarvestTask

  # ------------------------------------------------------------
  # Constants

  DUBLIN_CORE = 'oai_dc'
  private_constant :DUBLIN_CORE

  VALID_PREFIX_PATTERN = Regexp.new("^[#{URI::RFC2396_REGEXP::PATTERN::UNRESERVED}]+$")
  private_constant :VALID_PREFIX_PATTERN

  # ------------------------------------------------------------
  # Attributes

  attr_reader :oai_base_uri
  attr_reader :from_time
  attr_reader :until_time
  attr_reader :seconds_granularity
  attr_reader :metadata_prefix

  # ------------------------------------------------------------
  # Initializer

  # Creates a new +HarvestTask+ for harvesting from the specified OAI-PMH repository, with
  # an optional datetime range and metadata prefix. Note that the datetime range must be in UTC.
  #
  # @param oai_base_url [URI, String] the base URL of the repository. *(Required)*
  # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
  #   If +from_time+ is omitted, harvesting will extend back to the earliest datestamp in the
  #   repository. (Optional)
  # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
  #   If +until_time+ is omitted, harvesting will extend forward to the latest datestamp in the
  #   repository. (Optional)
  # @param seconds_granularity [Boolean] whether to include the full time out to the second in
  #   the from / until time range. (Defaults to false, i.e., days granularity.)
  # @param metadata_prefix [String, nil] the metadata prefix defining the metadata format requested
  #   from the repository. If +metadata_prefix+ is omitted, the prefix +oai_dc+ (Dublin Core)
  #   will be used.
  # @raise [RangeError] if +from_time+ is later than +until_time+.
  # @raise [ArgumentError] if +metadata_prefix+ contains invalid characters, i.e. URI reserved
  #   characters per {https://www.ietf.org/rfc/rfc2396.txt RFC 2396}, or if +from_time+ or
  #   +until_time+ is not in UTC.
  def initialize(oai_base_url:, from_time: nil, until_time: nil, seconds_granularity: false, metadata_prefix: DUBLIN_CORE)

    if from_time
      raise ArgumentError, "from_time #{from_time} must be in UTC" unless from_time.utc?
    end

    if until_time
      raise ArgumentError, "until_time #{until_time} must be in UTC" unless until_time.utc?
    end

    if from_time && until_time
      raise RangeError, "from_time #{from_time} must be <= until_time #{until_time}" unless from_time.to_i <= until_time.to_i
    end

    raise ArgumentError, "metadata_prefix ''#{metadata_prefix}'' must consist only of RFC 2396 URI unreserved characters" unless VALID_PREFIX_PATTERN =~ metadata_prefix

    @oai_base_uri = (oai_base_url.kind_of? URI) ? oai_base_url : URI.parse(oai_base_url)
    @from_time = from_time
    @until_time = until_time
    @seconds_granularity = seconds_granularity
    @metadata_prefix = metadata_prefix
  end

  # ------------------------------------------------------------
  # Methods

  # @return [Enumerable]
  def harvest
    client = OAI::Client.new @oai_base_uri.to_s

    opts = {}

    if from_time
      opts[:from] = seconds_granularity ? from_time : from_time.strftime('%Y-%m-%d')
    end
    if until_time
      opts[:until] = seconds_granularity ? until_time : until_time.strftime('%Y-%m-%d')
    end

    opts[:metadata_prefix] = metadata_prefix

    records = client.list_records(opts)
    records ? records.map { |r| Dash2::Harvester::OAIRecord.new(r) } : []
  end

end

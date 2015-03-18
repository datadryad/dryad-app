class Dash2::Harvester::HarvestTask

  DUBLIN_CORE = 'oai_dc'

  VALID_PREFIX_PATTERN = Regexp.new("^[#{URI::RFC2396_REGEXP::PATTERN::UNRESERVED}]+$")

  attr_reader :oai_base_uri
  attr_reader :from_time
  attr_reader :until_time
  attr_reader :metadata_prefix

  # TODO doc that we check time range validity to seconds, but repos may only support days
  def initialize(oai_base_url:, from_time: nil, until_time: nil, metadata_prefix: DUBLIN_CORE)

    if from_time && until_time
      raise RangeError, "from_time #{from_time} must be <= until_time #{until_time}" unless from_time.to_i <= until_time.to_i
    end

    raise ArgumentError, "metadata_prefix ''#{metadata_prefix}'' must consist only of RFC 2396 URI unreserved characters" unless VALID_PREFIX_PATTERN =~ metadata_prefix

    @oai_base_uri = (oai_base_url.kind_of? URI) ? oai_base_url : URI.parse(oai_base_url)
    @from_time = from_time
    @until_time = until_time
    @metadata_prefix = metadata_prefix
  end

end
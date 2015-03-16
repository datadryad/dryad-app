# TODO split HarvestTask and IndexTask, HarvestJob and IndexJob?

class Dash2::Harvester::HarvestTask

  # TODO do we want to expose the Solr option hash, or use explicit arguments?
  # TODO should all the arguments (OAI included) be in a hash?

  # Creates a new +HarvestTask+ for harvesting from the specified
  # OAI-PMH repository and indexing into the specified Solr instance.
  #
  # The +solr_opts+ hash keys are as follows:
  #
  # [+:url+] The Solr server URL (**required**)
  # [+:proxy+] The proxy server URL (optional)
  # [+:default_wt+] The default Solr response writer (see https://wiki.apache.org/solr/QueryResponseWriter)
  # [+:open_timeout+] The HTTP connection open timeout, in seconds
  # [+:read_timeout+] The HTTP connection read timeout, in seconds
  # [+:retry_503+] The number of times to retry in the event of a +503 Service Unavailable+ response
  # [+:retry_after_limit+] The maximum amount of time to sleep before retrying in the event of a 503 with +Retry-After+ header
  #
  # @param oai_url [String] the base URL of the OAI-PMH repository
  # @param solr_opts [Hash] the connection options for the Solr instance
  #
  # TODO @raise various errors on bad arguments
  def initialize(oai_url, solr_opts)

  end

  def schedule_harvest
    # TODO: HarvestJob.set(...scheduling?...).perform_later...
    HarvestJob.perform_later(self)
  end

end
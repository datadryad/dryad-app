# Harvests metadata from an OAI-PMH repository
#

class Dash2::Harvester::HarvestTask

  # Creates a new +HarvestTask+ for harvesting from the specified
  # OAI-PMH repository.
  #
  # @param oai_url [String] the base URL of the OAI-PMH repository
  #
  # TODO scheduling
  # TODO @raise various errors on bad arguments
  def initialize(oai_url)

  end

  def schedule_harvest
    # TODO: HarvestJob.set(...scheduling?...).perform_later...
    HarvestJob.perform_later(self)
  end

end
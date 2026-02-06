class DataciteService
  attr_reader :resource
  def initialize(resource)
    @resource = resource
  end

  def submit
    idg = Datacite::DoiGen.new(resource: @resource)
    idg.update_identifier_metadata!
  rescue Datacite::DoiGenError => e
    Rails.logger.error "Datacite::DoiGen - Unable to submit metadata changes for : '#{@resource&.identifier}'"
    Rails.logger.error e.message
    StashEngine::UserMailer.error_report(@resource, e).deliver_now
    raise e
  end
end

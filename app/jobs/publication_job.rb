class PublicationJob < BaseJob
  include Sidekiq::Worker
  sidekiq_options queue: :publication, retry: true, lock: :until_and_while_executing

  def perform(activity_id)
    @activity = StashEngine::CurationActivity.find_by(id: activity_id)
    @resource = StashEngine::Resource.with_public_metadata.find_by(id: @activity.resource_id)
    return if resource.nil?

    puts "#{Time.current} - performing indexing of published resource #{resource.id}"
    resource.submit_to_solr
    submit_to_datacite
  end

  private

  def submit_to_datacite
    return unless @activity.should_update_doi?

    idg = Datacite::DoiGen.new(resource: resource)
    idg.update_identifier_metadata!
  rescue Datacite::DoiGenError => e
    Rails.logger.error "Datacite::DoiGen - Unable to submit metadata changes for : '#{resource&.identifier}'"
    Rails.logger.error e.message
    StashEngine::UserMailer.error_report(resource, e).deliver_now
    raise e
  end

end

require_relative 'identifier_rake_functions'

# rubocop:disable Metrics/BlockLength
namespace :identifiers do
  desc 'Give resources missing a stash_engine_identifier one (run from main app, not engine)'
  task fix_missing: :environment do # loads rails environment
    IdentifierRakeFunctions.update_identifiers
  end

  desc "Update identifiers latest resource if they don't have one"
  task add_latest_resource: :environment do
    StashEngine::Identifier.where(latest_resource_id: nil).each do |se_identifier|
      puts "Updating identifier #{se_identifier.id}: #{se_identifier}"
      res = StashEngine::Resource.where(identifier_id: se_identifier.id).order(created_at: :desc).first
      if res.nil?
        se_identifier.destroy! # useless orphan identifier with no contents which should be deleted
      else
        se_identifier.update!(latest_resource_id: res.id)
      end
    end
  end

  desc 'Add searchable field contents for any identifiers missing it'
  task add_search: :environment do
    StashEngine::Identifier.where(search_words: nil).each do |se_identifier|
      puts "Updating identifier #{se_identifier} for search"
      se_identifier.update_search_words!
    end
  end

  desc 'update dataset license from tenant settings'
  task write_licenses: :environment do
    StashEngine::Identifier.all.each do |se_identifier|
      license = se_identifier&.latest_resource&.tenant&.default_license
      next if license.blank? || license == se_identifier.license_id
      puts "Updating license to #{license} for #{se_identifier}"
      se_identifier.update(license_id: license)
    end
  end

  desc 'convert old curation activity statuses to new enum format'
  task convert_curation_statuses: :environment do
    StashEngine::CurationActivity.where(status: 'Author Action Required').update_all(status: 'action_required')
    StashEngine::CurationActivity.where(status: 'Private for Peer Review').update_all(status: 'peer_review')
    StashEngine::CurationActivity.where(status: 'Status Unchanged').update_all(status: 'unchanged')
    StashEngine::CurationActivity.where(status: 'Versioned').update_all(status: 'in_progress')
    StashEngine::CurationActivity.where(status: 'Unsubmitted').update_all(status: 'in_progress')
    StashEngine::CurationActivity.all.each do |ca|
      ca.update(status: ca.status.downcase)
    end
  end

  desc 'seed curation activities'
  task seed_curation_activities: :environment do
    StashEngine::Identifier.includes(:curation_activities, :resources, :internal_data).all.each do |se_identifier|
      next unless se_identifier.curation_activities.empty?
      # Create an initial curation activity for each identifier
      #
      # Using the latest resource and its state (for user_id)
      #
      #   if the resource_state == 'submitted' then the curation status should be :submitted
      #   if the resource_state != 'submitted' then the curation status should be :in_progress
      #   if the resource_state == 'submitted' && the identifier has associated internal_data
      #                                               then the status should be :peer_review
      #
      se_resource = se_identifier.resources.includes(:resource_state).by_version_desc.first
      se_resource_state = se_resource.resource_states.order(updated_at: :desc).first

      status = if se_resource_state.resource_state == 'submitted'
                 se_identifier.has_journal? ? CurationActivity.peer_review : CurationActivity.submitted
               else
                 CurationActivity.in_progress
               end

      CurationActivity.create(
        identifier_id: se_identifier.id,
        resource_id: se_resource.id,
        user_id: se_resource_state.user_id,
        staus: status
      )
    end
  end

end
# rubocop:enable Metrics/BlockLength

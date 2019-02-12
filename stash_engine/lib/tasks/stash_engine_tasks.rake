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

  desc 'seed curation activities (warning: deletes all existing curation activities!)'
  task seed_curation_activities: :environment do
    # Delete all existing curation activity
    StashEngine::CurationActivity.delete_all

    StashEngine::Resource.includes(identifier: :internal_data).all.order(:identifier_id, :id).each do |resource|

      # Create an initial 'in_progress' curation activity for each identifier
      StashEngine::CurationActivity.create(
        resource_id: resource.id,
        user_id: resource.user_id,
        created_at: resource.created_at,
        updated_at: resource.created_at
      )

      # Using the latest resource and its state, add another activity if the
      # resource's resource_state is 'submitted'
      #
      #   if the resource_state == 'submitted' then the curation status should be :submitted
      #   if the resource_state == 'submitted' && the identifier has associated internal_data
      #                                               then the status should be :peer_review
      #
      next unless resource.current_state == 'submitted'
      StashEngine::CurationActivity.create(
        resource_id: resource.id,
        user_id: resource.user_id,
        status: resource.identifier.chargeable? ? 'peer_review' : 'submitted',
        created_at: resource.updated_at,
        updated_at: resource.updated_at
      )
    end
  end

end
# rubocop:enable Metrics/BlockLength

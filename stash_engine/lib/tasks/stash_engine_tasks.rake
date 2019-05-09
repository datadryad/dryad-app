require 'httparty'
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
        status: resource.identifier.internal_data.empty? ? 'submitted' : 'peer_review',
        created_at: resource.updated_at,
        updated_at: resource.updated_at
      )
    end
  end

  desc 'embargo legacy datasets that already had a publication_date in the future'
  task embargo_datasets: :environment do
    now = Date.today
    p "Embargoing legacy records with a resource whose publication_date >= '#{now}'"
    StashEngine::Resource.joins(:current_curation_activity)
      .includes(:current_curation_activity)
      .where('stash_engine_curation_activities.status != ?', 'embargoed')
      .where('stash_engine_resources.publication_date >= ?', now).each do |r|

      begin
        p "Embargoing: Identifier: #{r.identifier_id}, Resource: #{r.id}"
        StashEngine::CurationActivity.create(
          resource_id: r.id,
          user_id: r.current_curation_activity.user_id,
          status: 'embargoed',
          note: 'publiction date has not yet been reached'
        )
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
    end
  end

  desc 'publish datasets based on their publication_date'
  task publish_datasets: :environment do
    now = Date.today
    p "Publishing resources whose publication_date <= '#{now}'"
    StashEngine::Resource.joins(:current_curation_activity)
      .includes(:current_curation_activity)
      .where('stash_engine_curation_activities.status != ?', 'published')
      .where('stash_engine_resources.publication_date <= ?', now).each do |r|

      begin
        p "Publishing: Identifier: #{r.identifier_id}, Resource: #{r.id}"
        StashEngine::CurationActivity.create(
          resource_id: r.id,
          user_id: r.current_curation_activity.user_id,
          status: 'published',
          note: 'reached the publiction date'
        )
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
    end
  end

  desc 'populate publicationName'
  task load_publication_names: :environment do
    p "Searching CrossRef and the Journal API for publication names: #{Time.now}"
    already_loaded_ids = StashEngine::InternalDatum.where(data_type: 'publicationName').pluck(:identifier_id).uniq
    unique_issns = {}
    StashEngine::InternalDatum.where(data_type: 'publicationISSN').where.not(identifier_id: already_loaded_ids).each do |datum|
      if unique_issns[datum.value].present?
        # We already grabbed the title for the ISSN from Crossref
        title = unique_issns[datum.value]
      else
        response = HTTParty.get("https://api.crossref.org/journals/#{datum.value}", headers: { 'Content-Type': 'application/json' })
        if response.present? && response.parsed_response.present? && response.parsed_response['message'].present?
          title = response.parsed_response['message']['title']
          unique_issns[datum.value] = title unless unique_issns[datum.value].present?
          p "    found title, '#{title}', for #{datum.value}"
        end
      end
      StashEngine::InternalDatum.create(identifier_id: datum.identifier_id, data_type: 'publicationName', value: title) unless title.blank?
      # Submit the info to Solr if published/embargoed
      identifier = StashEngine::Identifier.where(id: datum.identifier_id)
      if identifier.present? && identifier.latest_resource.present?
        current_ca = identifier.latest_resource.current_curation_activity
        identifier.latest_resource.submit_to_solr if current_ca.present? && (current_ca.published? || current_ca.embargoed?)
      end
    end
    p "Finished: #{Time.now}"
  end

end
# rubocop:enable Metrics/BlockLength

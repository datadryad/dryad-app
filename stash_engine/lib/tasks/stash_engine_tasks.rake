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
    now = Time.now
    p "Embargoing resources whose publication_date > '#{now}'"
    query = <<-SQL
      SELECT ser.id, ser.identifier_id, seca.user_id
      FROM stash_engine_resources ser
        LEFT OUTER JOIN stash_engine_identifiers sei ON ser.identifier_id = sei.id
        INNER JOIN (SELECT MAX(r2.id) r_id FROM stash_engine_resources r2 GROUP BY r2.identifier_id) j1 ON j1.r_id = ser.id
        LEFT OUTER JOIN (SELECT ca2.resource_id, MAX(ca2.id) latest_curation_activity_id FROM stash_engine_curation_activities ca2 GROUP BY ca2.resource_id) j3 ON j3.resource_id = ser.id
        LEFT OUTER JOIN stash_engine_curation_activities seca ON seca.id = j3.latest_curation_activity_id
      WHERE seca.status != 'embargoed' AND ser.publication_date >
    SQL

    query += " '#{now.strftime('%Y-%m-%d %H:%M:%S')}'"
    ActiveRecord::Base.connection.execute(query).each do |r|
      begin
        p "Embargoing: Identifier: #{r[1]}, Resource: #{r[0]}"
        StashEngine::CurationActivity.create(
          resource_id: r[0],
          user_id: r[2],
          status: 'embargoed',
          note: 'Embargo Datasets CRON - publication date has not yet been reached, changing status to `embargo`'
        )
      rescue StandardError => e
        p "    Exception! #{e.message}"
        next
      end
    end
  end

  desc 'publish datasets based on their publication_date'
  task publish_datasets: :environment do
    now = Time.now
    p "Publishing resources whose publication_date <= '#{now}'"

    resources = StashEngine::Resource.need_publishing

    resources.each do |res|
      begin
        last_cur_activity = res.curation_activities.last
        res.curation_activities << StashEngine::CurationActivity.create(
          user_id: last_cur_activity.user_id,
          status: 'published',
          note: 'Publish Datasets CRON - reached the publication date, changing status to `published`'
        )
      rescue StandardError => e
        # note we get errors with test data updating DOI and some of the other callbacks on publishing
        p "    Exception! #{e.message}"
      end
    end
  end

  desc 'Set datasets to `submitted` when their peer review period has expired'
  task expire_peer_review: :environment do
    now = Date.today
    p "Setting resources whose peer_review_end_date <= '#{now}' to 'submitted' curation status"
    StashEngine::Resource.where(hold_for_peer_review: true)
      .where('stash_engine_resources.peer_review_end_date <= ?', now).each do |r|

      begin
        p "Expiring peer review for: Identifier: #{r.identifier_id}, Resource: #{r.id}"
        r.update(hold_for_peer_review: false, peer_review_end_date: nil)
        StashEngine::CurationActivity.create(
          resource_id: r.id,
          user_id: r.current_curation_activity.user_id,
          status: 'submitted',
          note: 'Expire Peer Review CRON - reached the peer review expiration date, changing status to `submitted`'
        )
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
    end
  end

  desc 'populate publicationName'
  task load_publication_names: :environment do
    p "Searching CrossRef and the Journal API for publication names: #{Time.now.utc}"
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
      identifier = StashEngine::Identifier.where(id: datum.identifier_id).first
      if identifier.present? && identifier.latest_resource.present?
        current_resource = identifier.latest_resource_with_public_metadata
        current_resource.submit_to_solr if current_resource.present?
      end
    end
    p "Finished: #{Time.now.utc}"
  end

end
# rubocop:enable Metrics/BlockLength

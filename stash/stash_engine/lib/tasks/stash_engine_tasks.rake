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

  desc 'embargo legacy datasets that already had a publication_date in the future -- note that this is somewhat drastic, and may over-embargo items.'
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

      p "Embargoing: Identifier: #{r[1]}, Resource: #{r[0]}"
      StashEngine::CurationActivity.create(
        resource_id: r[0],
        user_id: 0,
        status: 'embargoed',
        note: 'Embargo Datasets CRON - publication date has not yet been reached, changing status to `embargo`'
      )
    rescue StandardError => e
      p "    Exception! #{e.message}"
      next

    end
  end

  desc 'publish datasets based on their publication_date'
  task publish_datasets: :environment do
    now = Time.now
    p "Publishing resources whose publication_date <= '#{now}'"

    resources = StashEngine::Resource.need_publishing

    resources.each do |res|

      res.curation_activities << StashEngine::CurationActivity.create(
        user_id: 0,
        status: 'published',
        note: 'Publish Datasets CRON - reached the publication date, changing status to `published`'
      )
    rescue StandardError => e
      # note we get errors with test data updating DOI and some of the other callbacks on publishing
      p "    Exception! #{e.message}"

    end
  end

  # This task is deprecated, since we no longer want to automatically expire the review date,
  # we send reminders instead (below)
  desc 'Set datasets to `submitted` when their peer review period has expired'
  task expire_peer_review: :environment do
    now = Date.today
    p "Setting resources whose peer_review_end_date <= '#{now}' to 'submitted' curation status"
    StashEngine::Resource.where(hold_for_peer_review: true)
      .where('stash_engine_resources.peer_review_end_date <= ?', now).each do |r|

      if r.current_curation_status == 'peer_review'
        p "Expiring peer review for: Identifier: #{r.identifier_id}, Resource: #{r.id}"
        r.update(hold_for_peer_review: false, peer_review_end_date: nil)
        StashEngine::CurationActivity.create(
          resource_id: r.id,
          user_id: 0,
          status: 'submitted',
          note: 'Expire Peer Review CRON - reached the peer review expiration date, changing status to `submitted`'
        )
      else
        p "Removing peer review for: Identifier: #{r.identifier_id}, Resource: #{r.id} due to non-peer_review curation status"
        r.update(hold_for_peer_review: false, peer_review_end_date: nil)
      end
    rescue StandardError => e
      p "    Exception! #{e.message}"

    end
  end

  desc 'Email the submitter when a dataset has been in `peer_review` past the deadline, and the last reminder was too long ago'
  task peer_review_reminder: :environment do
    p 'Mailing users whose datasets have been in peer_review for a while...'
    StashEngine::Resource.where(hold_for_peer_review: true)
      .where('stash_engine_resources.peer_review_end_date <= ?', Date.today)
      .each do |r|

      reminder_flag = 'peer_review_reminder CRON'
      last_reminder = r.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last
      if r.current_curation_status == 'peer_review' &&
         r.identifier.latest_resource_id == r.id &&
         (last_reminder.blank? || last_reminder.created_at <= 1.month.ago)
        p "Reminding submitter about peer_review dataset. Identifier: #{r.identifier_id}, Resource: #{r.id} updated #{r.updated_at}"
        StashEngine::UserMailer.peer_review_reminder(r).deliver_now
        StashEngine::CurationActivity.create(
          resource_id: r.id,
          user_id: 0,
          status: r.current_curation_activity.status,
          note: "#{reminder_flag} - reminded submitter that this item is still in `peer_review`"
        )
      end
    rescue StandardError => e
      p "    Exception! #{e.message}"

    end
  end

  desc 'Email the submitter when a dataset has been `in_progress` for 3 days'
  task in_progess_reminder: :environment do
    p "Mailing users whose datasets have been in_progress since #{3.days.ago}"
    StashEngine::Resource.joins(:current_resource_state)
      .where("stash_engine_resource_states.resource_state = 'in_progress'")
      .where('stash_engine_resources.updated_at <= ?', 3.days.ago)
      .each do |r|

      reminder_flag = 'in_progress_reminder CRON'
      if r.curation_activities.where('note LIKE ?', "%#{reminder_flag}%").empty?
        p "Mailing submitter about in_progress dataset. Identifier: #{r.identifier_id}, Resource: #{r.id} updated #{r.updated_at}"
        StashEngine::UserMailer.in_progress_reminder(r).deliver_now
        StashEngine::CurationActivity.create(
          resource_id: r.id,
          user_id: 0,
          status: r.current_curation_activity.status,
          note: "#{reminder_flag} - reminded submitter that this item is still `in_progress`"
        )
      end
    rescue StandardError => e
      p "    Exception! #{e.message}"

    end
  end

  desc 'Generate a report of items that have been published in a given month'
  task shopping_cart_report: :environment do
    # Get the year-month specified in YEAR_MONTH environment variable.
    # If none, default to the previously completed month.
    if ENV['YEAR_MONTH'].blank?
      p 'No month specified, assuming last month.'
      year_month = 1.month.ago.strftime('%Y-%m')
    else
      year_month = ENV['YEAR_MONTH']
    end
    p "Writing Shopping Cart Report for #{year_month} to file..."
    CSV.open("shopping_cart_report_#{year_month}.csv", 'w') do |csv|
      csv << %w[DOI CreatedDate CurationStartDate ApprovalDate
                Size PaymentType PaymentID InstitutionName
                JournalName SponsorName]
      StashEngine::Identifier.publicly_viewable.each do |i|
        approval_date_str = i.approval_date&.strftime('%Y-%m-%d')
        next unless approval_date_str&.start_with?(year_month)

        created_date_str = i.created_at&.strftime('%Y-%m-%d')
        curation_start_date = i.resources.submitted.each do |r|
          break r.curation_start_date if r.curation_start_date.present?
        end
        curation_start_date_str = curation_start_date&.strftime('%Y-%m-%d')
        csv << [i.identifier, created_date_str, curation_start_date_str, approval_date_str,
                i.storage_size, i.payment_type, i.payment_id, i.submitter_affiliation&.long_name,
                i.publication_name, i.journal&.sponsor_name]
      end
    end
    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  desc 'Generate a summary report of all items in Dryad'
  task dataset_info_report: :environment do
    # Get the year-month specified in YEAR_MONTH environment variable.
    # If none, default to the previously completed month.
    if ENV['YEAR_MONTH'].blank?
      p 'No month specified, assuming all months.'
      year_month = nil
      filename = "dataset_info_report-#{Date.today.strftime('%Y-%m-%d')}.csv"
    else
      year_month = ENV['YEAR_MONTH']
      filename = "dataset_info_report-#{year_month}.csv"
    end

    p "Writing dataset info report to file #{filename}"
    CSV.open(filename, 'w') do |csv|
      csv << ['Dataset DOI', 'Article DOI', 'Approval Date', 'Title',
              'Size', 'Institution Name', 'Journal Name']
      StashEngine::Identifier.publicly_viewable.each do |i|
        approval_date_str = i.approval_date&.strftime('%Y-%m-%d')
        res = i.latest_viewable_resource
        next unless year_month.blank? || approval_date_str&.start_with?(year_month)

        csv << [i.identifier, i.publication_article_doi, approval_date_str, res&.title,
                i.storage_size, i.submitter_affiliation&.long_name, i.publication_name]
      end
    end
    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  desc 'populate payment info'
  task load_payment_info: :environment do
    p 'Populating payment information for published/embargoed items'
    StashEngine::Identifier.publicly_viewable.where(payment_type: nil).each do |i|
      i.record_payment
      p "#{i.id} #{i.identifier} #{i.payment_type} #{i.payment_id}"
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

  desc 'update search words for items that are obviously missing them'
  task update_missing_search_words: :environment do
    identifiers = StashEngine::Identifier.where('LENGTH(search_words) < 60 OR search_words IS NULL')
    puts "Updating search words for #{identifiers.length} items"
    identifiers.each_with_index do |id, idx|
      id&.update_search_words!
      puts "Updated #{idx + 1}/#{identifiers.length} items" if (idx + 1) % 100 == 0
    end
  end

  desc 'update search words for all items (in case we need to refresh them all)'
  task update_all_search_words: :environment do
    identifiers = StashEngine::Identifier.all
    puts "Updating search words for #{identifiers.length} items"
    identifiers.each_with_index do |id, idx|
      id&.update_search_words!
      puts "Updated #{idx + 1}/#{identifiers.length} items" if (idx + 1) % 100 == 0
    end
  end

end

namespace :curation_stats do
  desc 'Calculate any curation stats that are missing from v2 launch day until yesterday'
  task recalculate_all: :environment do
    launch_day = Date.new(2019, 9, 17)
    (launch_day..Date.today - 1.day).each do |date|
      print '.'
      stats = StashEngine::CurationStats.find_or_create_by(date: date)
      stats.recalculate unless stats.created_at > 2.seconds.ago
    end
  end

  desc 'Recalculate any curation stats from the past three days, not counting today'
  task update_recent: :environment do
    (Date.today - 4.days..Date.today - 1.day).each do |date|
      print '.'
      stats = StashEngine::CurationStats.find_or_create_by(date: date)
      stats.recalculate unless stats.created_at > 2.seconds.ago
    end
  end

end
# rubocop:enable Metrics/BlockLength

require 'httparty'
require 'stash/nih'
require 'stash/salesforce'
require 'stash/google/journal_g_mail'
require_relative 'identifier_rake_functions'

# rubocop:disable Metrics/BlockLength
namespace :identifiers do
  desc 'Give resources missing a stash_engine_identifier one (run from main app, not engine)'
  task fix_missing: :environment do # loads rails environment
    Tasks::IdentifierRakeFunctions.update_identifiers
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
      FROM stash_engine_identifiers sei
        JOIN stash_engine_resources ser ON sei.latest_resource_id = ser.id
        LEFT OUTER JOIN stash_engine_curation_activities seca ON ser.last_curation_activity_id = seca.id
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
      # NOTE: we get errors with test data updating DOI and some of the other callbacks on publishing
      p "    Exception! #{e.message}"

    end
  end

  desc 'remove in_progress versions and temporary files that have lingered for too long'
  task remove_old_versions: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    if dry_run
      puts ' ##### remove_old_versions DRY RUN -- not actually running delete commands'
    else
      puts ' ##### remove_old_versions -- Deleting old versions of datasets that are still in progress'
    end

    # Remove resources that have been "in progress" for more than a year without updates
    StashEngine::Resource.in_progress.each do |res|
      next unless res.updated_at < 1.year.ago
      next unless res.current_curation_status == 'in_progress'

      ident = res.identifier
      s3_dir = res.s3_dir_name(type: 'base')
      puts "ident #{ident.id} Res #{res.id} -- updated_at #{res.updated_at}"
      puts "   DESTROY s3 #{s3_dir}"
      Stash::Aws::S3.delete_dir(s3_key: s3_dir) unless dry_run
      puts "   DESTROY resource #{res.id}"
      res.destroy unless dry_run
    end

    # Remove directories in AWS that have no corresponding resource, or whose resource is already submitted
    s3_prefix = StashEngine::Resource.last.s3_dir_name(type: 'base')
    s3_prefix = if s3_prefix.include?('-')
                  s3_prefix.split('-').first
                else
                  ''
                end
    Stash::Aws::S3.objects(starts_with: s3_prefix).each do |s3o|
      id_prefix = s3o.key.split('/').first
      res_id = if id_prefix.include?('-')
                 id_prefix.split('-').last
               else
                 id_prefix
               end
      puts "checking S3 key #{s3o.key} -- id_prefix #{id_prefix} -- res_id #{res_id}"

      if StashEngine::Resource.exists?(id: res_id)
        r = StashEngine::Resource.find(res_id)
        if r.submitted? &&
           (r.zenodo_copies.where("copy_type LIKE 'software%' OR copy_type like 'supp%'").where.not(state: 'finished').count == 0)
          # if the resource is state == submitted and all zenodo transfers have completed, delete the data
          puts "   resource is submitted -- DELETE s3 dir #{id_prefix}"
          Stash::Aws::S3.delete_dir(s3_key: id_prefix) unless dry_run
        end
      else
        # there is no reasource, delete the files
        puts "   resource is deleted -- DELETE s3 dir #{id_prefix}"
        Stash::Aws::S3.delete_dir(s3_key: id_prefix) unless dry_run
      end
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
      .where('stash_engine_resources.peer_review_end_date <= ? OR stash_engine_resources.peer_review_end_date IS NULL', Date.today)
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
          status: r.last_curation_activity.status,
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
          status: r.last_curation_activity.status,
          note: "#{reminder_flag} - reminded submitter that this item is still `in_progress`"
        )
      end
    rescue StandardError => e
      p "    Exception! #{e.message}"

    end
  end

  desc 'Update NIH funder entry'
  task nih_funders_clean: :environment do
    # For each funder entry that is NIH
    StashEngine::Identifier.all.each do |i|
      next if i.latest_resource.nil?

      i.latest_resource.contributors.each do |contrib|
        next unless contrib.contributor_name == 'National Institutes of Health'

        puts "NIH lookup #{contrib.award_number}"
        # - look up the actual grant with the NIH API
        g = Stash::NIH.find_grant(contrib.award_number)
        next unless g.present?

        puts "NIH  found #{g['project_num']}"
        # - see which Institute or Center is the first funder
        ic = g['agency_ic_fundings'][0]['name']
        puts "NIH funder #{ic}"
        # - replace with the equivalent IC in Dryad
        Stash::NIH.set_contributor_to_ic(contributor: contrib, ic_name: ic)
      end
    end
  end

  desc 'Generate a report of items associated with common preprint servers'
  task preprints_report: :environment do
    p 'Writing preprints_report.csv...'
    CSV.open('preprints_report.csv', 'w') do |csv|
      csv << %w[DOI Relation RelatedIdentifierType RelatedIdetifier]

      related_identifiers = StashDatacite::RelatedIdentifier.where("related_identifier_type='arxiv' OR " \
                                                                   "LOWER(related_identifier) LIKE '%arxiv%' OR " \
                                                                   "related_identifier LIKE '%10.48550%' OR " \
                                                                   "related_identifier LIKE '%10.1101%' OR " \
                                                                   "related_identifier LIKE '%10.7287%' OR " \
                                                                   "work_type=#{StashDatacite::RelatedIdentifier.work_types[:preprint]}")
      visited_identifiers = []
      related_identifiers.each do |ri|
        i = ri.resource.identifier
        next if visited_identifiers.include?(i.id)

        visited_identifiers << i.id
        csv << [i.identifier, ri.relation_type, ri.related_identifier_type, ri.related_identifier]
      end
    end
  end

  desc 'Generate a report of the instances when a dataset is in_progress'
  task in_progress_detail_report: :environment do
    puts 'Writting in_progress_detail.csv'
    CSV.open('in_progress_detail.csv', 'w') do |csv|
      csv << %w[DOI PubDOI Version DateEnteredIP DateExitedIP StatusExitedTo DatasetSize CurrentStatus EverCurated? EverPublished? Journal WhoPays]
      StashEngine::Identifier.all.each_with_index do |i, ind|
        puts ind.to_s if (ind % 100) == 0
        in_ip = false
        date_entered_ip = i.created_at

        who_pays = if i.journal&.will_pay?
                     'journal'
                   elsif i.institution_will_pay?
                     'institution'
                   elsif i.submitter_affiliation&.fee_waivered?
                     'waiver'
                   elsif i.funder_will_pay?
                     'funder'
                   else
                     'user'
                   end

        ever_curated = i.resources.map(&:curation_activities).flatten.map(&:status).include?('curation')
        ever_published = i.resources.map(&:curation_activities).flatten.map(&:status).include?('published')

        i.resources.map(&:curation_activities).flatten.each do |ca|
          if ca.in_progress?
            next if in_ip # do nothing if it was already in in_progress

            in_ip = true
            date_entered_ip = ca.created_at
          elsif in_ip
            # the previous status was in_progress, but this satatus is not,
            # so close out the entry
            in_ip = false
            csv << [i.identifier, i.publication_article_doi,
                    ca.resource.stash_version.version, date_entered_ip, ca.created_at, ca.status,
                    ca.resource.size, i.latest_resource&.current_curation_status,
                    ever_curated, ever_published,
                    i.journal&.title, who_pays]
          end
        end

        # if we're at the end of the history and in_ip,
        # finalize the current stats before moving to next identifier
        next unless in_ip

        csv << [i.identifier, i.publication_article_doi,
                i.latest_resource.stash_version.version, date_entered_ip, 'None', 'None',
                i.latest_resource.size, i.latest_resource&.current_curation_status,
                ever_curated, ever_published,
                i.journal&.title, who_pays]
        in_ip = false
      end
    end
  end

  desc 'Generate a report of PPR to Curation'
  task ppr_to_curation_report: :environment do
    puts 'Writing ppr_to_curation.csv'
    CSV.open('ppr_to_curation.csv', 'w') do |csv|
      csv << %w[DOI CreatedAt]
      StashEngine::Identifier.all.each_with_index do |i, ind|
        puts ind.to_s if (ind % 100) == 0
        ppr_found = false
        i.resources.map(&:curation_activities).flatten.each do |ca|
          ppr_found = true if ca.peer_review?
          if ca.curation? && ppr_found
            csv << [i.identifier, i.created_at]
            break
          end
        end
      end
    end
  end

  desc 'Generate a detailed report of the instances when a dataset is in PPR'
  task ppr_detail_report: :environment do
    puts 'Writting ppr_detail.csv'
    CSV.open('ppr_detail.csv', 'w') do |csv|
      csv << %w[DOI PubDOI ManuNumber Version DateEnteredPPR DateExitedPPR StatusExitedTo DatasetSize Journal AutoPPR Integrated WhoPays]
      StashEngine::Identifier.all.each_with_index do |i, ind|
        puts ind.to_s if (ind % 100) == 0
        in_ppr = false
        date_entered_ppr = 'ERROR'

        who_pays = if i.journal&.will_pay?
                     'journal'
                   elsif i.institution_will_pay?
                     'institution'
                   elsif i.submitter_affiliation&.fee_waivered?
                     'waiver'
                   elsif i.funder_will_pay?
                     'funder'
                   else
                     'user'
                   end

        i.resources.map(&:curation_activities).flatten.each do |ca|
          if ca.peer_review?
            next if in_ppr # do nothing if it was already in PPR

            in_ppr = true
            date_entered_ppr = ca.created_at
          elsif in_ppr
            # the previous status was PPR, but this satatus is not,
            # so close out the entry
            in_ppr = false
            csv << [i.identifier, i.publication_article_doi, i.manuscript_number,
                    ca.resource.stash_version.version, date_entered_ppr, ca.created_at, ca.status,
                    ca.resource.size, i.journal&.title, i.journal&.default_to_ppr, i.journal&.manuscript_number_regex&.present?, who_pays]
          end
        end
        # if we're at the end of the history and in_ppr,
        # finalize the current stats before moving to next identifier
        next unless in_ppr

        csv << [i.identifier, i.publication_article_doi, i.manuscript_number,
                i.latest_resource.stash_version.version, date_entered_ppr, 'None', 'None',
                i.latest_resource.size, i.journal&.title, i.journal&.default_to_ppr, i.journal&.manuscript_number_regex&.present?, who_pays]
        in_ppr = false
      end
    end
  end

  desc 'Generate a report of datasets with associated rejection notices'
  task rejected_datasets_report: :environment do
    puts 'Writing rejected_datasets.csv'
    CSV.open('rejected_datasets.csv', 'w') do |csv|
      csv << %w[DOI CreatedAt MSID NumNotifications Published? CurrentStatus]

      rejected_manuscripts = StashEngine::Manuscript.where(status: 'rejected')

      rejected_manuscripts.each do |ms|
        same_manuscripts = StashEngine::Manuscript.where(manuscript_number: ms.manuscript_number)
        int_data = StashEngine::InternalDatum.where(data_type: 'manuscriptNumber', value: ms.manuscript_number)
        next unless int_data.present?

        i = StashEngine::Identifier.find(int_data.first&.identifier_id)
        next unless i

        puts "MS: #{ms.manuscript_number}  identifier #{int_data.first&.identifier_id}  same? #{same_manuscripts.size > 1}"
        csv << [i.identifier, i.created_at, ms.manuscript_number, same_manuscripts.size,
                i.date_last_published.present?, i.resources.last.current_curation_status]
      end
    end
  end

  desc 'Report on voided invoices'
  task voided_invoices_report: :environment do
    voids = Stash::Payments::Invoicer.find_recent_voids.map(&:id)

    # for each void, check if it exists in dryad
    alert_list = []
    voids.each do |invoice_id|
      puts "voided invoice #{invoice_id}"
      in_dryad = StashEngine::Identifier.where(payment_id: invoice_id)
      alert_list << in_dryad.first if in_dryad.present?
    end

    if alert_list.present?
      puts "Sending alert for identifiers #{alert_list.map(&:id)}"
      StashEngine::UserMailer.voided_invoices(alert_list).deliver_now
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
                Size PaymentType PaymentID WaiverBasis InstitutionName
                JournalName JournalISSN SponsorName]

      # Limit the query to datasets that existed at the time of the target report,
      # and have been updated the within the month of the target.
      limit_date = Date.parse("#{year_month}-01")
      limit_date_filter = "updated_at > '#{limit_date - 1.day}' AND created_at < '#{limit_date + 1.month}' "
      StashEngine::Identifier.publicly_viewable.where(limit_date_filter).each do |i|
        approval_date_str = i.approval_date&.strftime('%Y-%m-%d')
        next unless approval_date_str&.start_with?(year_month)

        created_date_str = i.created_at&.strftime('%Y-%m-%d')
        curation_start_date = i.resources.submitted.each do |r|
          break r.curation_start_date if r.curation_start_date.present?
        end
        curation_start_date_str = curation_start_date&.strftime('%Y-%m-%d')
        csv << [i.identifier, created_date_str, curation_start_date_str, approval_date_str,
                i.storage_size, i.payment_type, i.payment_id, i.waiver_basis, i.submitter_affiliation&.long_name,
                i.publication_name, i.publication_issn, i.journal&.sponsor&.name]
      end
    end
    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  desc 'Generate reports of items that should be billed for deferred journals'
  task deferred_journal_reports: :environment do
    # Get the input shopping cart report in SC_REPORT environment variable.
    if ENV['SC_REPORT'].blank?
      puts 'Usage: deferred_journal_reports SC_REPORT=<shopping_cart_report_filename>'
      exit
    else
      sc_report_file = ENV['SC_REPORT']
      puts "Producing deferred journal reports for #{sc_report_file}"
    end

    sc_report = CSV.parse(File.read(sc_report_file), headers: true)

    md = /(.*)shopping_cart_report_(.*).csv/.match(sc_report_file)
    time_period = nil
    prefix = ''
    deferred_filename = 'deferred_summary.csv'
    if md.present? && md.size > 1
      prefix = md[1]
      time_period = md[2]
      deferred_filename = "#{md[1]}#{time_period}_deferred_summary.csv"
    end

    puts "Writing summary report to #{deferred_filename}"
    CSV.open(deferred_filename, 'w') do |csv|
      csv << %w[SponsorName JournalName Count]
      curr_sponsor = nil
      sponsor_summary = []
      StashEngine::Journal.where(payment_plan_type: 'DEFERRED').order(:sponsor_id, :title).each do |j|
        if j.sponsor&.name != curr_sponsor
          write_sponsor_summary(name: curr_sponsor, file_prefix: prefix, report_period: time_period, table: sponsor_summary)
          sponsor_summary = []
          curr_sponsor = j.sponsor&.name
        end
        journal_item_count = 0
        sc_report.each do |item|
          if item['JournalISSN'] == j.issn
            journal_item_count += 1
            sponsor_summary << [item['DOI'], j.title, item['ApprovalDate']]
          end
        end
        csv << [j.sponsor&.name, j.title, journal_item_count]
      end
      write_sponsor_summary(name: curr_sponsor, file_prefix: prefix, report_period: time_period, table: sponsor_summary)
    end

    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  
  desc 'Generate reports of items that should be billed for tiered journals'
  task tiered_journal_reports: :environment do
    # Get the input shopping cart report in SC_REPORT environment variable.
    if ENV['SC_REPORT'].blank?
      puts 'Usage: tiered_journal_reports SC_REPORT=<shopping_cart_report_filename>'
      exit
    else
      sc_report_file = ENV['SC_REPORT']
      puts "Producing tiered journal reports for #{sc_report_file}"
    end

    sc_report = CSV.parse(File.read(sc_report_file), headers: true)

    md = /(.*)shopping_cart_report_(.*).csv/.match(sc_report_file)
    time_period = nil
    prefix = ''
    deferred_filename = 'tiered_summary.csv'
    if md.present? && md.size > 1
      prefix = md[1]
      time_period = md[2]
      tiered_filename = "#{md[1]}#{time_period}_tiered_summary.csv"
    end

    puts "Writing summary report to #{tiered_filename}"
    CSV.open(tiered_filename, 'w') do |csv|
      csv << %w[SponsorName JournalName Count Price]
      curr_sponsor = nil
      sponsor_summary = []
      StashEngine::Journal.where(payment_plan_type: 'TIERED').order(:sponsor_id, :title).each do |j|
        if j.sponsor&.name != curr_sponsor
          write_sponsor_summary(name: curr_sponsor, file_prefix: prefix, report_period: time_period, table: sponsor_summary)
          sponsor_summary = []
          curr_sponsor = j.sponsor&.name
        end
        journal_item_count = 0
        sc_report.each do |item|
          if item['JournalISSN'] == j.single_issn
            journal_item_count += 1
            sponsor_summary << [item['DOI'], j.title, item['ApprovalDate']]
          end
        end
        csv << [j.sponsor&.name, j.title, journal_item_count, tiered_price(journal_item_count)]
      end
      write_sponsor_summary(name: curr_sponsor, file_prefix: prefix, report_period: time_period, table: sponsor_summary)
    end

    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end


  def tiered_price(count)
    return nil unless count.is_a?(Integer)
    free_datasets = 10
    
    if count <= free_datasets
      price = 0
    elsif count <= 100
      price = (count - free_datasets) * 135
    elsif count <= 250
      price = (count - free_datasets) * 100
    elsif count <= 500
      price = (count - free_datasets) * 85
    elsif count <= 500
      price = (count - free_datasets) * 55
    end

    "$#{price}"
  end
  
  # Write a PDF that Dryad can send to the sponsor, summarizing the datasets published
  # rubocop:disable Metrics/MethodLength
  def write_sponsor_summary(name:, file_prefix:, report_period:, table:)
    return if name.blank? || table.blank?

    filename = "#{file_prefix}deferred_submissions_#{StashEngine::GenericFile.sanitize_file_name(name)}_#{report_period}.pdf"
    puts "Writing sponsor summary to #{filename}"
    table_content = ''
    table.each do |row|
      table_content << "<tr><td>#{row[0]}</td><td>#{row[1]}</td><td>#{row[2]}</td></tr>"
    end
    html_content = <<-HTMLEND
      <head><style>
      tr:nth-child(even) {
          background-color: #f2f2f2;
      }
      th {
          background-color: #005581;
          color: white;
          text-align: left;
          padding: 10px;
      }
      td {
          padding: 10px;
      }
      </style></head>
      <h1>#{name}</h1>
      <p>Dryad submissions accepted under a deferred payment plan.<br/>
      Reporting period: #{report_period}<br/>
      Report generated on: #{Date.today}</p>
      <table>
       <tr><th width="25%">DOI</th>
           <th width="55%">Journal Name</th>
           <th width="20%">Approval Date</th></tr>
       #{table_content}
      </table>
    HTMLEND

    pdf = WickedPdf.new.pdf_from_string(html_content)
    File.open(filename, 'wb') do |file|
      file << pdf
    end
  end
  # rubocop:enable Metrics/MethodLength

  desc 'Generate a report of Dryad authors and their countries'
  task geographic_authors_report: :environment do
    CSV.open('geographic_authors_report.csv', 'w') do |csv|
      csv << ['Dataset DOI', 'Author First', 'Author Last', 'Institution', 'Country']
      StashEngine::Identifier.publicly_viewable.each do |i|
        res = i.latest_viewable_resource
        res.authors.each do |a|
          affil = a.affiliation
          csv << [i.identifier,
                  a&.author_first_name,
                  a&.author_last_name,
                  affil&.long_name,
                  affil&.country_name]
        end
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

  desc 'Generate a report of the curation timeline for each dataset'
  task curation_timeline_report: :environment do
    launch_day = Date.new(2019, 9, 17)
    datasets = StashEngine::Identifier.where(created_at: launch_day..Date.today)
    CSV.open('curation_timeline_report.csv', 'w') do |csv|
      csv << %w[DOI CreatedDate CurationStartDate TimesCurated ApprovalDate Size NumFiles FileFormats]
      datasets.each_with_index do |i, idx|
        puts("#{idx}/#{datasets.size}") if idx % 100 == 0
        approval_date_str = i.approval_date&.strftime('%Y-%m-%d')
        created_date_str = i.created_at&.strftime('%Y-%m-%d')
        next unless i.resources.submitted.present?

        curation_start_date = i.resources.submitted.each do |r|
          break r.curation_start_date if r.curation_start_date.present?
        end
        next if curation_start_date.is_a?(Array) # There really isn't a start date, loop returns the array of resources
        next unless curation_start_date > launch_day

        curation_start_date_str = curation_start_date&.strftime('%Y-%m-%d')

        times_curated = 0
        in_curation = false
        i.resources.each do |r|
          r.curation_activities.each do |ca|
            if in_curation && %w[embargoed withdrawn published action_required].include?(ca.status)
              # detect moves from in_curation to out
              in_curation = false
            elsif !in_curation && %w[curation].include?(ca.status)
              # detect and count moves from out of curation to in_curation
              in_curation = true
              times_curated += 1
            end
          end
        end

        # Skip datasets that bypassed the normal curation process. These are mostly items that
        # had problems during the migration from the v1 server, so they were "created" after
        # launch day, even though they are actually older items.
        next unless times_curated > 0

        num_files = i.latest_resource.data_files.size

        file_formats = i.latest_resource.data_files.map(&:upload_content_type).uniq.sort

        csv << [i.identifier, created_date_str, curation_start_date_str, times_curated, approval_date_str,
                i.storage_size, num_files, file_formats]
      end
    end
  end

  desc 'Curation passes per dataset'
  task curation_passes: :environment do
    # Only look at content for the past two years, since curation practices are constantly changing
    # Note that this may slightly undercount, since recent datasets haven't had time for multiple passes
    start_day = 2.years.ago
    datasets = StashEngine::Identifier.where(created_at: start_day..Date.today)
    ids_seen = 0
    total_curation_count = 0
    datasets.each do |i|
      next unless %w[published embargoed].include?(i.pub_state) # only count datasets that reached a final state

      curation_count = 0
      in_curation = false
      cas = i.resources.map(&:curation_activities).flatten
      cas.each do |ca|
        if ca.peer_review? || ca.action_required? || ca.published? || ca.withdrawn?
          in_curation = false
        elsif ca.curation? && !in_curation
          in_curation = true
          curation_count += 1
        end
      end
      ids_seen += 1
      total_curation_count += curation_count
      puts "#{i.id} -- #{curation_count} -- average #{total_curation_count.to_f / ids_seen}"
    end
  end

  desc 'Report on first date for each status'
  task status_dates: :environment do
    launch_day = Date.new(2019, 9, 18)

    CSV.open('curation_status_dates.csv', 'w') do |csv|
      csv << %w[DOI
                Journal
                PaymentType
                InProgressDate
                PPRDate
                SubmittedDate
                CurationDate
                AARDate
                EmbargoedDate
                PublishedDate
                WithdrawnDate]
      # For each dataset, submitted after launch day...
      StashEngine::Identifier.where("created_at > '#{launch_day}'").each do |i|
        r = i.first_submitted_resource
        next unless r

        cas = i.resources.map(&:curation_activities).flatten
        next unless cas.present?

        csv << [i.identifier, # DOI
                i.journal&.title,
                i.payment_type,
                cas.find(&:in_progress?)&.created_at,
                cas.find(&:peer_review?)&.created_at,
                cas.find(&:submitted?)&.created_at,
                cas.find(&:curation?)&.created_at,
                cas.find(&:action_required?)&.created_at,
                cas.find(&:embargoed?)&.created_at,
                cas.find(&:published?)&.created_at,
                cas.find(&:withdrawn?)&.created_at]
      end
    end
  end

  desc 'Calculate milestones from v2 launch day'
  task milestones: :environment do
    launch_day = Date.new(2019, 9, 17)

    CSV.open('curation_milestones.csv', 'w') do |csv|
      csv << %w[DOI
                CurationCompletedDate
                ApprovalDate
                TimeToCuration
                TimeInCuration
                TimeAARToNon
                TimeAARToCuration
                TimeToApproval]
      # For each dataset, submitted after launch day...
      StashEngine::Identifier.publicly_viewable.where("created_at > '#{launch_day}'").each do |i|
        approval_date_str = i.approval_date&.strftime('%Y-%m-%d')
        curation_completed_date_str = i.curation_completed_date&.strftime('%Y-%m-%d')

        r = i.first_submitted_resource
        next unless r

        # TimeToCuration = time from first availability (CurationStartDate) to first actual curation note
        ttc_start = i.date_available_for_curation
        ttc_end = i.date_first_curated
        time_to_curation = (ttc_end - ttc_start).to_i / 1.day if ttc_start && ttc_end

        # TimeInCuration = time from first actual curation to approval
        time_in_curation = (i.approval_date - ttc_end).to_i / 1.day if ttc_end && i.approval_date

        # TimeAARToNon = time from first AAR to following non-AAR status (including in_progress)
        time_aar_to_non = (i.aar_end_date - i.aar_date).to_i / 1.day if i.aar_date && i.aar_end_date

        # TimeAARToCuration = time from first AAR to following curation status (author has actually returned it)
        post_aar_curation_date = nil
        i.resources.reverse_each do |res|
          res.curation_activities.each do |ca|
            if ca.curation? && i.aar_date && (ca.created_at >= i.aar_date)
              post_aar_curation_date = ca.created_at
              break
            end
          end
        end
        time_aar_to_curation = (post_aar_curation_date - i.aar_date).to_i / 1.day if i.aar_date && post_aar_curation_date

        # TimeToApproval = time from submission to approval
        time_to_approval = (i.approval_date - r.submitted_date).to_i / 1.day if i.approval_date && r.submitted_date

        csv << [i.identifier, # DOI
                curation_completed_date_str, # CurationCompletedDate
                approval_date_str, # ApprovalDate aka PublicationDate
                time_to_curation,
                time_in_curation,
                time_aar_to_non,
                time_aar_to_curation,
                time_to_approval]
      end
    end
  end
end

namespace :journals do
  desc 'Clean journals that have exact name matches except for an asterisk'
  task clean_titles_with_asterisks: :environment do
    data = StashEngine::InternalDatum.where("data_type = 'publicationName' and value like '%*'")
    data.each do |d|
      name = d.value
      next unless name.ends_with?('*')

      j = StashEngine::Journal.find_by_title(name[0..-2])
      next unless j.present?

      puts "Cleaning journal: #{name}"
      StashEngine::Journal.replace_uncontrolled_journal(old_name: name, new_id: j.id)
    end
    nil
  end

  desc 'Compare journal differences between Dryad and Salesforce'
  task check_salesforce_sync: :environment do

    dry_run = if ENV['DRY_RUN'].blank?
                true
              else
                ENV['DRY_RUN'] != 'false'
              end

    puts 'Processing with DRY_RUN' if dry_run

    jj = Stash::Salesforce.db_query("SELECT Id, Name FROM Account where Type='Journal'")
    jj.each do |j|
      found_journal = StashEngine::Journal.find_by_title(j['Name'])
      puts "MISSING from Dryad -- #{j['Name']}" unless found_journal.present?
    end

    StashEngine::Journal.all.each do |j|
      # Only check the journal in Salesforce if Dryad has a business relationship
      # with the journal (payment plan or integration)
      next unless j.payment_plan_type.present? || j.manuscript_number_regex.present?

      sf_id = Stash::Salesforce.find_account_by_name(j.title)
      unless sf_id.present?
        puts "MISSING from Salesforce -- #{j.title}"
        next
      end

      sfj = Stash::Salesforce.find(obj_type: 'Account', obj_id: sf_id)
      if sfj['ISSN__c'] != j.issn
        puts "Updating ISSN in SF from #{sfj['ISSN__c']} to #{j.issn}"
        Stash::Salesforce.update(obj_type: 'Account', obj_id: sf_id, kv_hash: { ISSN__c: j.issn }) unless dry_run
      end

      sf_parent_id = sfj['ParentId']
      sf_parent = Stash::Salesforce.find(obj_type: 'Account', obj_id: sf_parent_id)
      puts "SPONSOR MISMATCH for #{j.issn} -- #{j.sponsor&.name} -- #{sf_parent['Name']}" if j.sponsor&.name != sf_parent['Name']
    end
    nil
  end
end

namespace :journal_email do
  desc 'Acquire a token for working with the target GMail account'
  task validate_gmail_connection: :environment do
    Stash::Google::JournalGMail.validate_gmail_connection
  end

  desc 'Process all messages in the GMail account that have the target label'
  task process: :environment do
    Stash::Google::JournalGMail.process
  end

  desc 'Clean outdated manuscript entries'
  task clean_old_manuscripts: :environment do
    StashEngine::Manuscript.where('created_at < ?', 2.years.ago).delete_all
  end
end

# rubocop:enable Metrics/BlockLength

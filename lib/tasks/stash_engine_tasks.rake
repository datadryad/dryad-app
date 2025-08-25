# :nocov:
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
      log "Updating identifier #{se_identifier.id}: #{se_identifier}"
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
      log "Updating identifier #{se_identifier} for search"
      se_identifier.update_search_words!
    end
  end

  desc 'update dataset license from tenant settings'
  task write_licenses: :environment do
    StashEngine::Identifier.find_each do |se_identifier|
      license = se_identifier&.latest_resource&.tenant&.default_license
      next if license.blank? || license == se_identifier.license_id

      log "Updating license to #{license} for #{se_identifier}"
      se_identifier.update(license_id: license)
    end
  end

  desc 'seed curation activities (warning: deletes all existing curation activities!)'
  task seed_curation_activities: :environment do
    # Delete all existing curation activity
    StashEngine::CurationActivity.delete_all

    StashEngine::Resource.includes(identifier: :internal_data).find_each do |resource|

      # Create an initial 'in_progress' curation activity for each identifier
      StashEngine::CurationActivity.create(
        resource_id: resource.id,
        user_id: resource.submitter.id,
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
        user_id: resource.submitter.id,
        status: resource.identifier.internal_data.empty? ? 'submitted' : 'peer_review',
        created_at: resource.updated_at,
        updated_at: resource.updated_at
      )
    end
  end

  desc 'embargo legacy datasets that already had a publication_date in the future -- note that this is somewhat drastic, and may over-embargo items.'
  task embargo_datasets: :environment do
    now = Time.now
    log "Embargoing resources whose publication_date > '#{now}'"
    query = <<-SQL
      SELECT ser.id, ser.identifier_id, seca.user_id
      FROM stash_engine_identifiers sei
        JOIN stash_engine_resources ser ON sei.latest_resource_id = ser.id AND ser.deleted_at IS NULL
        LEFT OUTER JOIN stash_engine_curation_activities seca ON ser.last_curation_activity_id = seca.id AND seca.deleted_at IS NULL
      WHERE seca.status != 'embargoed'
        AND sei.deleted_at IS NULL
        AND ser.publication_date >
    SQL

    query += " '#{now.strftime('%Y-%m-%d %H:%M:%S')}'"
    ActiveRecord::Base.connection.execute(query).each do |r|

      log "Embargoing: Identifier: #{r[1]}, Resource: #{r[0]}"
      StashEngine::CurationActivity.create(
        resource_id: r[0],
        user_id: 0,
        status: 'embargoed',
        note: 'Embargo Datasets CRON - publication date has not yet been reached, changing status to `embargo`'
      )
    rescue StandardError => e
      log "    Exception! #{e.message}"
      next

    end
  end

  desc 'publish datasets based on their publication_date'
  task publish_datasets: :environment do
    now = Time.now
    log "Publishing resources whose publication_date <= '#{now}'"

    StashEngine::Resource.need_publishing.find_each do |res|
      # only release if it's the latest version of the resource
      next unless res.id == res.identifier.last_submitted_resource.id

      res.curation_activities << StashEngine::CurationActivity.create(
        user_id: 0,
        status: 'published',
        note: 'Publish Datasets CRON - reached the publication date, changing status to `published`'
      )
    rescue StandardError => e
      # NOTE: we get errors with test data updating DOI and some of the other callbacks on publishing
      log "    Exception! #{e.message}"

    end
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:remove_abandoned_datasets -- --dry_run true
  desc 'remove abandoned, unpublished datasets that will never be published'
  task remove_abandoned_datasets: :environment do
    args = Tasks::ArgsParser.parse :dry_run
    # This task cleans up files from datasets that may have had some activity, but they have no real chance of being published.
    dry_run = args.dry_run == 'true'
    if dry_run
      log ' ##### remove_abandoned_datasets DRY RUN -- not actually running delete commands'
    else
      log ' ##### remove_abandoned_datasets -- Deleting old versions of datasets that are still in progress'
    end

    removed_files_note = 'remove_abandoned_datasets CRON - removing data files from abandoned dataset'

    StashEngine::Identifier.where(pub_state: [nil, 'withdrawn', 'unpublished']).find_each do |i|
      next if i.date_first_published.present?
      next unless %w[in_progress withdrawn].include?(i.latest_resource&.current_curation_status)
      next if i.latest_resource.curation_activities&.map(&:note)&.include?(removed_files_note)

      # Double-check whether it was ever published -- even though we checked the date_first_published,
      # some older datasets did not have this date set properly in the internal metadata before they were
      # withdrawn, so we need to be certain.
      next if i.resources.map(&:curation_activities).flatten.map(&:status).include?('published')

      # Find the last activity by a "real" user (not the system user)
      last_user_activity = nil
      i.latest_resource&.curation_activities&.reverse_each do |ca|
        if ca.user_id.present? && ca.user_id > 0
          last_user_activity = ca.created_at
          break
        end
      end

      # Only remove the files if two years have passed since the last user activity
      if last_user_activity.present? && last_user_activity < 2.years.ago
        log "ABANDONED #{i.identifier} -- #{i.id} -- size #{i.latest_resource.size}"

        if dry_run
          log ' -- skipping deletion due to DRY_RUN setting'
        else
          log ' -- deleting data files'
          # Record the file deletion
          StashEngine::CurationActivity.create(
            resource_id: i.latest_resource.id,
            user_id: 0,
            status: 'withdrawn',
            note: removed_files_note
          )

          # Perform the actual removal
          i.resources.each do |r|
            # Delete files from temp upload directory, if it exists
            s3_dir = r.s3_dir_name(type: 'base')
            Stash::Aws::S3.new.delete_dir(s3_key: s3_dir)
            # Delete files from permanent storage, if it exists
            perm_bucket = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
            if r.download_uri&.include?('ark%3A%2F')
              m = /ark.*/.match(r.download_uri)
              base_path = CGI.unescape(m.to_s)
              merritt_version = r.stash_version.merritt_version
              perm_bucket.delete_dir(s3_key: "#{base_path}|#{merritt_version}|producer")
              perm_bucket.delete_dir(s3_key: "#{base_path}|#{merritt_version}|system")
              perm_bucket.delete_file(s3_key: "#{base_path}|manifest")
            else
              perm_bucket.delete_dir(s3_key: "v3/#{s3_dir}")
            end

            # mark all files as deleted
            r.generic_files.update(file_deleted_at: Time.current)

            # Important! Retain the metadata for this dataset, so curators can determine what happened to it
          end

          # create a new version to mark all files as deleted
          new_res = DuplicateResourceService.new(i.latest_resource, StashEngine::User.system_user).call
          new_res.update skip_emails: true
          new_res.generic_files.update(file_deleted_at: Time.current, file_state: 'deleted')
          new_res.current_state = 'submitted'

          # Record the file deletion
          StashEngine::CurationActivity.create(
            resource_id: new_res.id,
            user_id: 0,
            status: 'withdrawn',
            note: 'remove_abandoned_datasets CRON - mark files as deleted',
            skip_emails: true
          )
        end
      end
    end
    Kernel.exit
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:remove_old_versions -- --dry_run true
  desc 'clean up in_progress versions and temporary files that are disconnected from datasets'
  task remove_old_versions: :environment do
    # This task cleans up garbage versions of datasets, which may have been abandoned, but they may also have been accidentally created
    # and not properly connected to an Identifier object
    args = Tasks::ArgsParser.parse :dry_run
    # This task cleans up datasets that may have had some activity, but they have no real chance of being published.
    dry_run = args.dry_run == 'true'
    if dry_run
      log ' ##### remove_old_versions DRY RUN -- not actually running delete commands'
    else
      log ' ##### remove_old_versions -- Deleting old versions of datasets that are still in progress'
    end

    # Remove resources that have been "in progress" for more than a year without updates
    StashEngine::Resource.in_progress.where('stash_engine_resources.updated_at < ?', 1.year.ago).find_each do |res|
      next unless res.current_curation_status == 'in_progress'

      ident = res.identifier
      s3_dir = res.s3_dir_name(type: 'base')
      log "ident #{ident&.id || 'MISSING'} Res #{res.id} -- updated_at #{res.updated_at}"
      log "   DESTROY temporary s3 contents #{s3_dir}"
      Stash::Aws::S3.new.delete_dir(s3_key: s3_dir) unless dry_run
      log "   DESTROY resource #{res.id}"
      next if dry_run

      StashEngine::DeleteDatasetsService.new(res).call
    end

    # Remove directories in AWS temporary storage that have no corresponding resource, or whose resource is already submitted
    s3_prefix = StashEngine::Resource.last.s3_dir_name(type: 'base')
    s3_prefix = if s3_prefix.include?('-')
                  s3_prefix.split('-').first
                else
                  ''
                end
    Stash::Aws::S3.new.objects(starts_with: s3_prefix).each do |s3o|
      id_prefix = s3o.key.split('/').first
      res_id = if id_prefix.include?('-')
                 id_prefix.split('-').last
               else
                 id_prefix
               end
      log "checking S3 key #{s3o.key} -- id_prefix #{id_prefix} -- res_id #{res_id}"

      if StashEngine::Resource.exists?(id: res_id)
        r = StashEngine::Resource.find(res_id)
        if r.submitted? &&
           (r.zenodo_copies.where("copy_type LIKE 'software%' OR copy_type like 'supp%'").where.not(state: 'finished').count == 0)
          # if the resource is state == submitted and all zenodo transfers have completed, delete the temporary data
          log "   resource is submitted -- DELETE s3 dir #{id_prefix}"
          Stash::Aws::S3.new.delete_dir(s3_key: id_prefix) unless dry_run
        end
      else
        # there is no reasource that corresponds to this S3 dir, so delete the temporary files
        log "   resource is deleted -- DELETE s3 dir #{id_prefix}"
        Stash::Aws::S3.new.delete_dir(s3_key: id_prefix) unless dry_run
      end
    end
    exit
  end

  desc 'Email the submitter 1 time 6 months from publication, when a primary article is not linked'
  task doi_linking_invitation: :environment do
    log 'Mailing users whose datasets have no primary article and were published 6 months ago...'
    reminder_flag = 'doi_linking_invitation CRON'
    StashEngine::Identifier.publicly_viewable.find_each do |i|
      next if i.publication_article_doi
      next if i.resources.map(&:curation_activities).flatten.map(&:note).join.include?(reminder_flag)
      next unless i.date_first_published <= 6.months.ago
      next if i.latest_resource.nil?

      log "Inviting DOI link. Identifier: #{i.id}, Resource: #{i.latest_resource&.id} updated #{i.latest_resource&.updated_at}"
      StashEngine::UserMailer.doi_invitation(i.latest_resource).deliver_now
      StashEngine::CurationActivity.create(
        resource_id: i.latest_resource&.id,
        user_id: 0,
        status: i.latest_resource&.last_curation_activity&.status,
        note: "#{reminder_flag} - invited submitter to link an article DOI"
      )
    rescue StandardError => e
      log "    Exception! #{e.message}"

    end
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:in_progress_reminder_1_day
  desc 'Email the submitter when a dataset has been `in_progress` for 1 day'
  task in_progress_reminder_1_day: :environment do
    Reminders::DatasetRemindersService.new.send_in_progress_reminders_by_day(1)
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:in_progress_reminder_3_days
  desc 'Email the submitter when a dataset has been `in_progress` for 3 days'
  task in_progress_reminder_3_days: :environment do
    Reminders::DatasetRemindersService.new.send_in_progress_reminders_by_day(3)
  end

  desc "Email the submitter when a dataset is in 'action_required' 1 time at 2 weeks"
  task action_required_reminder: :environment do
    Reminders::DatasetRemindersService.new.action_required_reminder
  end

  desc 'Update NIH funder entry'
  task nih_funders_clean: :environment do
    # For each funder entry that is NIH
    StashEngine::Identifier.find_each do |i|
      next if i.latest_resource.nil?

      i.latest_resource.contributors.each do |contrib|
        next unless contrib.contributor_name == 'National Institutes of Health'

        log "NIH lookup #{contrib.award_number}"
        # - look up the actual grant with the NIH API
        g = Stash::NIH.find_grant(contrib.award_number)
        next unless g.present?

        log "NIH  found #{g['project_num']}"
        # - see which Institute or Center is the first funder
        ic = g['agency_ic_fundings'][0]['name']
        log "NIH funder #{ic}"
        # - replace with the equivalent IC in Dryad
        Stash::NIH.set_contributor_to_ic(contributor: contrib, ic_name: ic)
      end
    end
  end

  desc 'Curation and publication report'
  task curation_publication_report: :environment do
    log 'Writing curation_publication_report.csv...'
    launch_day = Date.new(2019, 9, 17)
    CSV.open('curation_publication_report.csv', 'w') do |csv|
      csv << %w[DOI CreatedAt Size NumFiles FileExtensions DaysSubmissionToApproval DaysInCuration]
      StashEngine::Identifier.publicly_viewable.where("created_at > '#{launch_day + 1.day}'").find_each do |i|
        num_files = i.latest_resource.data_files.select { |f| %w[copied created].include?(f[:file_state]) }.size
        file_extensions = i.latest_resource.data_files.map { |f| File.extname(f.upload_file_name).downcase }.uniq

        r = i.first_submitted_resource
        next unless r

        # TimeInCuration = time from first actual curation to approval
        ttc_end = i.date_first_curated
        time_in_curation = (i.approval_date - ttc_end).to_i / 1.day if ttc_end && i.approval_date

        # don't list old migrated content
        next unless ttc_end
        next unless i.approval_date
        next unless time_in_curation >=	0

        # TimeToApproval = time from submission to approval
        time_to_approval = (i.approval_date - r.submitted_date).to_i / 1.day if i.approval_date && r.submitted_date

        csv << [i.identifier, i.created_at, i.latest_resource.size, num_files, file_extensions, time_to_approval, time_in_curation]
      end
    end
  end

  desc 'Generate a report of datasets without primary articles'
  task datasets_without_primary_articles_report: :environment do
    FileUtils.mkdir_p(REPORTS_DIR)
    outfile = File.join(REPORTS_DIR, 'datasets_without_primary_articles.csv')
    log "Writing #{outfile}..."
    CSV.open(outfile, 'w') do |csv|
      csv << %w[DataDOI CreatedAt ISSN Title Authors Institutions Relations]
      StashEngine::Identifier.publicly_viewable.find_each do |i|
        d = i.publication_article_doi
        next unless d.blank?

        r = i.latest_viewable_resource
        next unless r.present?

        authors = r.authors&.map(&:author_standard_name)
        rors = r.authors&.map(&:affiliations)&.flatten&.map(&:ror_id)&.uniq&.compact
        rors = nil if rors.blank?
        relations = r.related_identifiers&.map { |ri| [ri.work_type, ri.related_identifier] }
        relations = nil if relations.blank?

        csv << [i.identifier, i.created_at, i.publication_issn, r.title, authors, rors, relations]
      end
    end
  end

  desc 'Generate a report of datasets with possible articles'
  task datasets_with_possible_articles_report: :environment do
    FileUtils.mkdir_p(REPORTS_DIR)
    outfile = File.join(REPORTS_DIR, 'datasets_with_possible_articles.csv')
    log "Writing #{outfile}..."
    CSV.open(outfile, 'w') do |csv|
      csv << %w[ID Identifier ISSN]
      StashEngine::Identifier.publicly_viewable.joins(latest_resource: :resource_publication)
        .where.not(resource_publication: { publication_issn: nil })
        .where.not(
          id: StashEngine::Resource
            .joins(:related_identifiers)
            .where({
                     "#{StashDatacite::RelatedIdentifier.table_name}.related_identifier_type": 'doi',
                     "#{StashDatacite::RelatedIdentifier.table_name}.work_type": 'primary_article'
                   })
            .pluck(:identifier_id)
        ).find_each do |i|
        csv << [i.id, i.identifier, i.publication_issn]
      end
    end
  end

  desc 'Generate a report of items associated with common preprint servers'
  task preprints_report: :environment do
    log 'Writing preprints_report.csv...'
    CSV.open('preprints_report.csv', 'w') do |csv|
      csv << %w[DOI Relation RelatedIdentifierType RelatedIdetifier]
      visited_identifiers = []
      StashDatacite::RelatedIdentifier
        .where("related_identifier_type='arxiv' OR " \
               "LOWER(related_identifier) LIKE '%arxiv%' OR " \
               "related_identifier LIKE '%10.48550%' OR " \
               "related_identifier LIKE '%10.1101%' OR " \
               "related_identifier LIKE '%10.7287%' OR " \
               "work_type=#{StashDatacite::RelatedIdentifier.work_types[:preprint]}")
        .find_each do |ri|
        i = ri.resource.identifier
        next if visited_identifiers.include?(i.id)

        visited_identifiers << i.id
        csv << [i.identifier, ri.relation_type, ri.related_identifier_type, ri.related_identifier]
      end
    end
  end

  desc 'Generate a report of the instances when a dataset is in_progress'
  task in_progress_detail_report: :environment do
    log 'Writting in_progress_detail.csv'
    CSV.open('in_progress_detail.csv', 'w') do |csv|
      csv << %w[DOI PubDOI Version DateEnteredIP DateExitedIP StatusExitedTo DatasetSize CurrentStatus EverCurated? EverPublished? Journal WhoPays]
      StashEngine::Identifier.find_each.with_index do |i, ind|
        log ind if (ind % 100) == 0
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
    log 'Writing ppr_to_curation.csv'
    CSV.open('ppr_to_curation.csv', 'w') do |csv|
      csv << %w[DOI CreatedAt]
      StashEngine::Identifier.find_each.with_index do |i, ind|
        log ind if (ind % 100) == 0
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
    log 'Writting ppr_detail.csv'
    CSV.open('ppr_detail.csv', 'w') do |csv|
      csv << %w[DOI PubDOI ManuNumber Version DateEnteredPPR DateExitedPPR StatusExitedTo DatasetSize Journal AutoPPR Integrated WhoPays]
      StashEngine::Identifier.find_each.with_index do |i, ind|
        log ind if (ind % 100) == 0
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
    log 'Writing rejected_datasets.csv'
    CSV.open('rejected_datasets.csv', 'w') do |csv|
      csv << %w[DOI CreatedAt MSID NumNotifications Published? CurrentStatus]

      StashEngine::Manuscript.where(status: 'rejected').find_each do |ms|
        same_manuscripts = StashEngine::Manuscript.where(manuscript_number: ms.manuscript_number)
        pub = StashEngine::ResourcePublication.find_by(manuscript_number: ms.manuscript_number)
        next unless pub.present?

        i = pub.resource.identifier
        next unless i

        log "MS: #{ms.manuscript_number}  identifier #{int_data.first&.identifier_id}  same? #{same_manuscripts.size > 1}"
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
      log "voided invoice #{invoice_id}"
      in_dryad = StashEngine::Identifier.where(payment_id: invoice_id)
      alert_list << in_dryad.first if in_dryad.present?
    end

    if alert_list.present?
      log "Sending alert for identifiers #{alert_list.map(&:id)}"
      StashEngine::UserMailer.voided_invoices(alert_list).deliver_now
    end
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:shopping_cart_report -- --year_month 2024-05
  desc 'Generate a report of items that have been published in a given month'
  task shopping_cart_report: :environment do
    args = Tasks::ArgsParser.parse(:year_month)
    # Get the year-month specified in --year_month argument.
    # If none, default to the previously completed month.
    year_month = if args.year_month.blank?
                   log 'No month specified, assuming last month.'
                   1.month.ago.strftime('%Y-%m')
                 else
                   args.year_month
                 end

    log "Writing Shopping Cart Report for #{year_month} to file..."
    CSV.open("shopping_cart_report_#{year_month}.csv", 'w') do |csv|
      csv << %w[DOI CreatedDate CurationStartDate ApprovalDate
                Size PaymentType PaymentID WaiverBasis InstitutionName
                JournalName JournalISSN SponsorName CurrentStatus]

      # Limit the query to datasets that existed at the time of the target report,
      # and have been updated the within the month of the target.
      limit_date = Date.parse("#{year_month}-01")
      limit_date_filter = "updated_at > '#{limit_date - 1.day}' AND created_at < '#{limit_date + 1.month}' "
      StashEngine::Identifier.publicly_viewable.where(limit_date_filter).find_each do |i|
        approval_date_str = i.approval_date&.strftime('%Y-%m-%d')
        next unless approval_date_str&.start_with?(year_month)

        created_date_str = i.created_at&.strftime('%Y-%m-%d')
        curation_start_date = i.resources.submitted.each do |r|
          break r.curation_start_date if r.curation_start_date.present?
        end
        curation_start_date_str = curation_start_date&.strftime('%Y-%m-%d')
        csv << [i.identifier, created_date_str, curation_start_date_str, approval_date_str,
                i.storage_size, i.payment_type, i.payment_id, i.waiver_basis, i.submitter_affiliation&.long_name,
                i.publication_name, i.publication_issn, i.journal&.sponsor&.name, i&.resources&.last&.current_curation_status]
      end
    end
    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:deferred_journal_reports -- --sc_report /path/to/file
  desc 'Generate reports of items that should be billed for deferred journals'
  task deferred_journal_reports: :environment do
    args = Tasks::ArgsParser.parse(:sc_report)
    # Get the input shopping cart report in --sc_report argument.
    if args.sc_report.blank?
      log 'Usage: rails deferred_journal_reports -- --sc_report <shopping_cart_report_filename>'
      exit
    end

    sc_report_file = args.sc_report
    log "Producing deferred journal reports for #{sc_report_file}"

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

    log "Writing summary report to #{deferred_filename}"
    CSV.open(deferred_filename, 'w') do |csv|
      csv << %w[SponsorName JournalName Count]
      curr_sponsor = nil
      sponsor_summary = []
      StashEngine::Journal.where(payment_plan_type: 'DEFERRED').order(:sponsor_id, :title).each do |j|
        if j.sponsor&.name != curr_sponsor
          Reports::Payments::Base.new.write_sponsor_summary(name: curr_sponsor, file_prefix: prefix, report_period: time_period,
                                                            table: sponsor_summary, payment_plan: 'deferred')
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
        csv << [j.sponsor&.name, j.title, journal_item_count]
      end
      Reports::Payments::Base.new.write_sponsor_summary(name: curr_sponsor, file_prefix: prefix, report_period: time_period, table: sponsor_summary,
                                                        payment_plan: 'deferred')
    end

    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:journal_2025_reports -- --sc_report /path/to/file
  desc 'Generate reports of items that should be billed for tiered journals'
  task journal_2025_fee_reports: :environment do
    args = Tasks::ArgsParser.parse(:sc_report)
    # Get the input shopping cart report in --base_report and --sc_report arguments.
    if args.sc_report.blank?
      log 'Usage: journal_2025_fee_reports -- --base_report <shopping_cart_base_filename>'
      exit
    end

    Reports::Payments::Journal2025Fees.new.call(args)

    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:tenant_2025_fee_reports -- --sc_report /path/to/file
  desc 'Generate reports of items that should be billed for tiered journals'
  task tenant_2025_fee_reports: :environment do
    args = Tasks::ArgsParser.parse(:sc_report)
    # Get the input shopping cart report in --base_report and --sc_report arguments.
    if args.sc_report.blank?
      log 'Usage: tenant_2025_fee_reports -- --base_report <shopping_cart_base_filename>'
      exit
    end

    Reports::Payments::Tenant2025Fees.new.call(args)

    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:tiered_journal_reports -- --base_report /path/to/base_report --sc_report /path/to/file
  desc 'Generate reports of items that should be billed for tiered journals'
  task tiered_journal_reports: :environment do
    args = Tasks::ArgsParser.parse(:sc_report, :base_report)
    # Get the input shopping cart report in --base_report and --sc_report arguments.
    if args.sc_report.blank? || args.base_report.blank?
      log 'Usage: tiered_journal_reports -- --base_report <shopping_cart_base_filename> --sc_report <shopping_cart_report_filename>'
      exit
    end

    base_report_file = args.base_report
    sc_report_file = args.sc_report
    log "Producing tiered journal reports for #{sc_report_file}, using base in #{base_report_file}"

    base_values = tiered_base_values(base_report_file)
    log "Calculated base values #{base_values}"

    sc_report = CSV.parse(File.read(sc_report_file), headers: true)

    md = /(.*)shopping_cart_report_(.*).csv/.match(sc_report_file)
    time_period = nil
    prefix = ''
    tiered_filename = 'tiered_summary.csv'
    if md.present? && md.size > 1
      prefix = md[1]
      time_period = md[2]
      tiered_filename = "#{md[1]}#{time_period}_tiered_summary.csv"
    end

    log "Writing summary report to #{tiered_filename}"
    CSV.open(tiered_filename, 'w') do |csv|
      csv << %w[SponsorName JournalName Count Price]
      sponsor_summary = []
      sponsor_total_count = 0
      StashEngine::JournalOrganization.all.each do |org|
        journals = org.journals_sponsored_deep
        journals.each do |j|
          next unless j.payment_plan_type == 'TIERED' && j.top_level_org == org

          journal_item_count = 0
          sc_report.each do |item|
            if item['JournalISSN'] == j.single_issn
              journal_item_count += 1
              sponsor_summary << [item['DOI'], j.title, item['ApprovalDate']]
            end
          end
          csv << [org.name, j.title, journal_item_count, '']
          sponsor_total_count += journal_item_count
        end
        next if sponsor_summary.blank?

        base = base_values[org.name] || 0
        csv << [org.name, 'TOTAL', sponsor_total_count, tiered_price(sponsor_total_count, base)]
        Reports::Payments::Base.new.write_sponsor_summary(name: org.name, file_prefix: prefix, report_period: time_period,
                                                          table: sponsor_summary, payment_plan: 'tiered')
        sponsor_summary = []
        sponsor_total_count = 0
      end
    end

    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  # Calculates each sponsor's "base" number of submissions, using data from prior quarters
  def tiered_base_values(base_report_file)
    base_values = {}
    base_report = CSV.parse(File.read(base_report_file), headers: true)
    sponsor_total_count = 0
    StashEngine::JournalOrganization.all.each do |org|
      journals = org.journals_sponsored_deep
      journals.each do |j|
        next unless j.payment_plan_type == 'TIERED' && j.top_level_org == org

        journal_item_count = 0
        base_report.each do |item|
          journal_item_count += 1 if item['JournalISSN'] == j.single_issn
        end
        sponsor_total_count += journal_item_count
      end
      next if sponsor_total_count == 0

      base_values[org.name] = sponsor_total_count
      sponsor_total_count = 0
    end
    base_values
  end

  # the tiered_price is based on the total number of datasets, including the current quarter
  # current_count should be the number of datasets in the current quarter
  # cumulative_count should be the total cumulative datasets, *including* the current quarter
  def tiered_price(current_count, cumulative_count)
    return nil unless current_count.is_a?(Integer) && cumulative_count.is_a?(Integer)

    free_datasets = 10

    base_price = if cumulative_count <= free_datasets
                   0
                 elsif cumulative_count <= 100
                   135
                 elsif cumulative_count <= 250
                   100
                 elsif cumulative_count <= 500
                   85
                 else
                   55
                 end

    "$#{current_count * base_price}"
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:tiered_tenant_reports -- --base_report /path/to/base_report --sc_report /path/to/file
  desc 'Generate reports of items that should be billed for tiered tenant institutions'
  task tiered_tenant_reports: :environment do
    args = Tasks::ArgsParser.parse(:sc_report, :base_report)
    # Get the input shopping cart report in --base_report and --sc_report arguments.
    if args.sc_report.blank? || args.base_report.blank?
      log 'Usage: tiered_tenant_reports -- --base_report <shopping_cart_base_filename> --sc_report <shopping_cart_report_filename>'
      exit
    end

    base_report_file = args.base_report
    sc_report_file = args.sc_report
    log "Producing tiered tenant reports for #{sc_report_file}, using base in #{base_report_file}"

    base_values = tiered_tenant_base_values(base_report_file)
    log "Calculated base values #{base_values}"

    sc_report = CSV.parse(File.read(sc_report_file), headers: true)

    md = /(.*)shopping_cart_report_(.*).csv/.match(sc_report_file)
    time_period = nil
    prefix = ''
    tiered_filename = 'tiered_tenant_summary.csv'
    if md.present? && md.size > 1
      prefix = md[1]
      time_period = md[2]
      tiered_filename = "#{md[1]}#{time_period}_tiered_tenant_summary.csv"
    end

    log "Writing summary report to #{tiered_filename}"
    CSV.open(tiered_filename, 'w') do |csv|
      csv << %w[SponsorName InstitutionName Count Price]
      sponsor_summary = []
      sponsor_total_count = 0
      StashEngine::Tenant.tiered.each do |tenant|
        next if tenant.sponsor

        consortium = tenant.consortium
        consortium.each do |c|
          tenant_item_count = 0
          sc_report.each do |item|
            if item['PaymentID'] == c.id
              tenant_item_count += 1
              sponsor_summary << [item['DOI'], c.short_name, item['ApprovalDate']]
            end
          end
          csv << [tenant.short_name, c.short_name, tenant_item_count, '']
          sponsor_total_count += tenant_item_count
        end
        next if sponsor_summary.blank?

        base = base_values[tenant.short_name] || 0
        csv << [tenant.short_name, 'TOTAL', sponsor_total_count, tiered_price(sponsor_total_count, base)]
        Reports::Payments::Base.new.write_sponsor_summary(name: tenant.short_name, file_prefix: prefix, report_period: time_period,
                                                          table: sponsor_summary, payment_plan: 'tiered')
        sponsor_summary = []
        sponsor_total_count = 0
      end
    end

    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  # Calculates each sponsor's "base" number of submissions, using data from prior quarters
  def tiered_tenant_base_values(base_report_file)
    base_values = {}
    base_report = CSV.parse(File.read(base_report_file), headers: true)
    sponsor_total_count = 0
    StashEngine::Tenant.tiered.each do |tenant|
      next if tenant.sponsor

      consortium = tenant.consortium
      consortium.each do |c|
        tenant_item_count = 0
        base_report.each do |item|
          tenant_item_count += 1 if item['PaymentID'] == c.id
        end
        sponsor_total_count += tenant_item_count
      end
      next if sponsor_total_count == 0

      base_values[tenant.short_name] = sponsor_total_count
      sponsor_total_count = 0
    end
    base_values
  end

  # example: RAILS_ENV=production bundle exec rake identifiers:geographic_authors_report -- --year_month 2024-05
  desc 'Generate a report of Dryad authors and their countries'
  task geographic_authors_report: :environment do
    args = Tasks::ArgsParser.parse(:year_month)
    # Get the year-month specified in --year_month argument.
    # If none, default to the previously completed month.
    year_month = if args.year_month.blank?
                   log 'No month specified, assuming last month.'
                   1.month.ago.strftime('%Y-%m')
                 else
                   args.year_month
                 end

    log "Writing Geographic Authors Report for #{year_month} to file..."
    CSV.open('geographic_authors_report.csv', 'w') do |csv|
      csv << ['Dataset DOI', 'Author First', 'Author Last', 'Institution', 'Country']
      # Limit the query to datasets that existed at the time of the target report,
      # and have been updated the within the month of the target.
      limit_date = Date.parse("#{year_month}-01")
      limit_date_filter = "updated_at > '#{limit_date - 1.day}' AND created_at < '#{limit_date + 1.month}' "
      StashEngine::Identifier.publicly_viewable.where(limit_date_filter).find_each do |i|
        res = i.latest_viewable_resource
        res&.authors&.each do |a|
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

  # example: RAILS_ENV=production bundle exec rake identifiers:dataset_info_report -- --year_month 2024-05
  desc 'Generate a summary report of all items in Dryad'
  task dataset_info_report: :environment do
    args = Tasks::ArgsParser.parse(:year_month)
    # Get the year-month specified in --year_month argument.
    # If none, default to the previously completed month.

    if args.year_month.blank?
      log 'No month specified, assuming last month.'
      year_month = 1.month.ago.strftime('%Y-%m')
      filename = "dataset_info_report-#{Date.today.strftime('%Y-%m-%d')}.csv"
    else
      year_month = args.year_month
      filename = "dataset_info_report-#{year_month}.csv"
    end

    log "Writing dataset info report to file #{filename}"
    CSV.open(filename, 'w') do |csv|
      csv << ['Dataset DOI', 'Article DOI', 'Approval Date', 'Title',
              'Size', 'Institution Name', 'Journal Name']
      StashEngine::Identifier.publicly_viewable.find_each do |i|
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

  # example: RAILS_ENV=production bundle exec rake identifiers:biorxiv_report --
  desc 'Generate a summary report of all bioRxiv and medRxiv items in Dryad'
  task biorxiv_report: :environment do
    filename = "biorxiv_report-#{Date.today.strftime('%Y-%m-%d')}.csv"
    log "Writing biorxiv report to file #{filename}"
    CSV.open(filename, 'w') do |csv|
      csv << ['Dataset DOI', 'Status', 'Preprint Server', 'Preprint Link',
              'Journal Name', 'Article DOI', 'Title',
              'Size', 'Institution Name',
              'Submitter First', 'Submitter Last', 'Submitter Email']
      ii = Set[]

      # find matches by preprint server or journal
      biorxiv = StashEngine::JournalIssn.find('2692-8205').journal
      medrxiv = StashEngine::JournalIssn.find('3067-2007').journal
      c = 0
      StashEngine::Identifier.find_each do |i|
        c += 1
        puts ". Identifier #{c}" if c % 1000 == 0
        ps = i.preprint_server
        next unless ps == 'bioRxiv' || ps == 'medRxiv' || i.journal == biorxiv || i.journal == medrxiv

        ii.add(i)
      end

      # find by related identifiers
      c = 0
      StashDatacite::RelatedIdentifier.find_each do |ri|
        c += 1
        puts ". RelatedIdentifier #{c}" if c % 1000 == 0
        next unless ri.related_identifier.include?('10.1101')

        ii.add(ri.resource.identifier)
      end

      # process results
      ii.each do |i|
        r = i.latest_resource
        preprint_link = nil
        r.related_identifiers.each do |ri|
          preprint_link = ri.related_identifier if ri.related_identifier.include?('10.1101')
        end
        csv << [i.identifier, r.current_curation_status, i.preprint_server, preprint_link,
                i.publication_name, i.publication_article_doi, r&.title,
                i.storage_size, i.submitter_affiliation&.long_name,
                r.submitter.first_name, r.submitter.last_name, r.submitter.email]
      end
    end

    # Exit cleanly (don't let rake assume that an extra argument is another task to process)
    exit
  end

  desc 'populate payment info'
  task load_payment_info: :environment do
    log 'Populating payment information for published/embargoed items'
    StashEngine::Identifier.publicly_viewable.where(payment_type: nil).each do |i|
      i.record_payment
      log "#{i.id} #{i.identifier} #{i.payment_type} #{i.payment_id}"
    end
  end

  desc 'populate publicationName'
  task load_publication_names: :environment do
    log "Searching CrossRef and the Journal API for publication names: #{Time.now.utc}"
    unique_issns = {}
    StashEngine::Identifier.joins(latest_resource: :resource_publication).where(resource_publication: { publication_name: nil })
      .where.not(resource_publication: { publication_issn: nil }).each do |datum|
      if unique_issns[datum.publication_issn].present?
        # We already grabbed the title for the ISSN from Crossref
        title = unique_issns[datum.publication_issn]
      else
        response = HTTParty.get("https://api.crossref.org/journals/#{datum.publication_issn}", headers: { 'Content-Type': 'application/json' })
        if response.present? && response.parsed_response.present? && response.parsed_response['message'].present?
          title = response.parsed_response['message']['title']
          unique_issns[datum.publication_issn] = title unless unique_issns[datum.publication_issn].present?
          log "    found title, '#{title}', for #{datum.publication_issn}"
        end
      end
      datum.update(publicationName: title) unless title.blank?
      # Submit the info to Solr if published/embargoed
      identifier = datum.resource.identifier
      current_resource = identifier.latest_resource_with_public_metadata
      current_resource.submit_to_solr if current_resource.present?
    end
    log "Finished: #{Time.now.utc}"
  end

  desc 'update search words for items that are obviously missing them'
  task update_missing_search_words: :environment do
    identifiers = StashEngine::Identifier.where('LENGTH(search_words) < 60 OR search_words IS NULL')
    log "Updating search words for #{identifiers.length} items"
    identifiers.each_with_index do |id, idx|
      id&.update_search_words!
      log "Updated #{idx + 1}/#{identifiers.length} items" if (idx + 1) % 100 == 0
    end
  end

  desc 'update search words for all items (in case we need to refresh them all)'
  task update_all_search_words: :environment do
    count = StashEngine::Identifier.count
    log "Updating search words for #{count} items"
    StashEngine::Identifier.find_each.with_index do |id, idx|
      id&.update_search_words!
      log "Updated #{idx + 1}/#{count} items" if (idx + 1) % 100 == 0
    end
  end
end

namespace :curation_stats do
  desc 'Calculate any curation stats that are missing from v2 launch day until yesterday'
  task recalculate_all: :environment do
    launch_day = Date.new(2019, 9, 17)
    (launch_day..Time.now.utc.to_date - 1.day).each do |date|
      print '.'
      stats = StashEngine::CurationStats.find_or_create_by(date: date)
      stats.recalculate unless stats.created_at > 2.seconds.ago
    end
  end

  desc 'Recalculate any curation stats from the past three days, not counting today'
  task update_recent: :environment do
    (Time.now.utc.to_date - 4.days..Time.now.utc.to_date - 1.day).each do |date|
      print '.'
      stats = StashEngine::CurationStats.find_or_create_by(date: date)
      stats.recalculate unless stats.created_at > 2.seconds.ago
    end
  end

  desc 'Generate a report of the curation timeline for each dataset'
  task curation_timeline_report: :environment do
    launch_day = Date.new(2019, 9, 17)
    CSV.open('curation_timeline_report.csv', 'w') do |csv|
      csv << %w[DOI CreatedDate CurationStartDate TimesCurated ApprovalDate Size NumFiles FileFormats]
      StashEngine::Identifier.where(created_at: launch_day..Time.now.utc.to_date).find_each.with_index do |i, idx|
        log("#{idx}/#{datasets.size}") if idx % 100 == 0
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
    ids_seen = 0
    total_curation_count = 0
    StashEngine::Identifier.where(created_at: start_day..Time.now.utc.to_date).find_each do |i|
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
      log "#{i.id} -- #{curation_count} -- average #{total_curation_count.to_f / ids_seen}"
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
      StashEngine::Identifier.where("created_at > '#{launch_day}'").find_each do |i|
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
      StashEngine::Identifier.publicly_viewable.where("created_at > '#{launch_day}'").find_each do |i|
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
  task match_titles_to_issns: :environment do
    StashEngine::ResourcePublication.where.not(publication_name: [nil, '']).where(publication_issn: [nil, '']).find_each do |d|

      journal = StashEngine::Journal.find_by_title(d.publication_name)
      next unless j.present?

      log "Cleaning journal: #{name}"
      StashEngine::Journal.replace_uncontrolled_journal(old_name: d.publication_name, new_journal: journal)
    end
    nil
  end
  desc 'Clean journals that have exact name matches except for an asterisk'
  task clean_titles_with_asterisks: :environment do
    StashEngine::InternalDatum.where("data_type = 'publicationName' and value like '%*'").find_each do |d|
      name = d.value
      next unless name.ends_with?('*')

      j = StashEngine::Journal.find_by_title(name[0..-2])
      next unless j.present?

      log "Cleaning journal: #{name}"
      StashEngine::Journal.replace_uncontrolled_journal(old_name: name, new_journal: j)
    end
    StashEngine::ResourcePublication.where("publication_name like '%*'").find_each do |d|
      name = d.publication_name
      next unless name.ends_with?('*')

      j = StashEngine::Journal.find_by_title(name[0..-2])
      next unless j.present?

      log "Cleaning journal: #{name}"
      StashEngine::Journal.replace_uncontrolled_journal(old_name: name, new_journal: j)
    end
    nil
  end

  # example: RAILS_ENV=production bundle exec rake journals:check_salesforce_sync -- --dry_run true
  desc 'Compare journal differences between Dryad and Salesforce'
  task check_salesforce_sync: :environment do
    args = Tasks::ArgsParser.parse(:dry_run)
    dry_run = if args.dry_run.blank?
                true
              else
                args.dry_run != 'false'
              end

    log 'Processing with DRY_RUN' if dry_run

    jj = Stash::Salesforce.db_query("SELECT Id, Name FROM Account where Type='Journal'")
    jj.find_each do |j|
      found_journal = StashEngine::Journal.find_by_title(j['Name'])
      log "MISSING from Dryad -- #{j['Name']}" unless found_journal.present?
    end

    StashEngine::Journal.find_each do |j|
      # Only check the journal in Salesforce if Dryad has a business relationship
      # with the journal (payment plan or integration)
      next unless j.payment_plan_type.present? || j.manuscript_number_regex.present?

      sf_id = Stash::Salesforce.find_account_by_name(j.title)
      unless sf_id.present?
        log "MISSING from Salesforce -- #{j.title}"
        next
      end

      sfj = Stash::Salesforce.find(obj_type: 'Account', obj_id: sf_id)
      if sfj['ISSN__c'] != j.single_issn
        log "Updating ISSN in SF from #{sfj['ISSN__c']} to #{j.single_issn}"
        Stash::Salesforce.update(obj_type: 'Account', obj_id: sf_id, kv_hash: { ISSN__c: j.single_issn }) unless dry_run
      end

      sf_parent_id = sfj['ParentId']
      sf_parent = Stash::Salesforce.find(obj_type: 'Account', obj_id: sf_parent_id)
      log "SPONSOR MISMATCH for #{j.single_issn} -- #{j.sponsor&.name} -- #{sf_parent['Name']}" if j.sponsor&.name != sf_parent['Name']
    end
    exit
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

def log(message)
  return if Rails.env.test?

  puts message
end
# rubocop:enable Metrics/BlockLength
# :nocov:

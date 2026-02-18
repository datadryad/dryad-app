# :nocov:
require 'yaml'
require_relative 'dev_ops/passenger'
require_relative 'dev_ops/download_uri'
require_relative 'dev_ops/download_s3'
require 'rsolr'
require 'ezid/client'
require 'fileutils'

# rubocop:disable Metrics/BlockLength
namespace :dev_ops do

  # example: RAILS_ENV=development bundle exec rake dev_ops:processing
  desc 'Shows processing submissions'
  task processing: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
    in_process = StashEngine::Resource.joins(:current_resource_state).where("stash_engine_resource_states.resource_state = 'processing'")
    puts "resource_id\tuser_id\tcurrent_status\tupdated at\ttitle" if in_process.count > 0
    in_process.find_each do |i|
      puts "#{i.id}\t#{i.user_id}\t#{i.current_resource_state_id}\t#{i.updated_at}\t#{i.title}"
    end
  end

  desc 'update unfilled sizes'
  task fill_size: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
    StashEngine::Identifier.where(storage_size: nil).each do |i|
      lsr = i.last_submitted_resource
      next if lsr.nil? || lsr.download_uri.blank? || lsr.update_uri.blank?

      puts "Adding size to #{i}"
      total_dataset_size = 0
      resource.data_files.each do |data_file|
        total_dataset_size += data_file.upload_file_size unless data_file.file_state == 'deleted'
      end
      i.update(storage_size: total_dataset_size)
    end
  end

  desc 'fill missing file sizes'
  task fill_file_size: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
    StashEngine::DataFile.where(upload_file_size: [0, nil]).find_each do |data_file|
      resource = data_file.resource
      next unless resource && resource.current_resource_state && resource.current_resource_state.resource_state == 'submitted'

      puts "updating resource #{resource.id} & #{resource.identifier}"
      s3 = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
      s3_size = s3.size(s3_key: data_file.s3_permanent_path)
      data_file.update(upload_file_size: s3_size)
    end
  end

  desc 'Update the description fields to have html content (generated from text)'
  task htmlize: :environment do
    require 'script/htmlize_descriptions'

    puts "Are you sure you want to update desciption text to html in #{Rails.env}?  (Type 'yes' to proceed, 'no' to preview.)"
    response = $stdin.gets
    if response.strip.casecmp('YES').zero?
      StashDatacite::Description.find_each do |desc|
        item = Script::HtmlizeDescriptions.new(desc.description)
        next if item.html? || desc.description.blank?

        out_html = item.text_as_html
        desc.update(description: out_html)
        puts "Updated description id: #{desc.id}"
        puts out_html
        puts ''
      end

    else
      StashDatacite::Description.find_each do |desc|
        item = Script::HtmlizeDescriptions.new(desc.description)
        next if item.html? || desc.description.blank?

        puts desc.resource.id if desc.resource
        puts item.text_as_html
        puts ''
      end
    end
  end

  desc 'Backup database by mysqldump'
  task backup: :environment do
    directory = '/home/ec2-user/deploy/shared/cron/backups'
    FileUtils.mkdir_p directory
    # YAML.safe_load is preferred by rubocop but it causes the read to fail on `unknown alias 'default'`
    # rubocop:disable Security/YAMLLoad
    db = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'database.yml'))).result, aliases: true)[Rails.env]
    # rubocop:enable Security/YAMLLoad
    file = File.join(directory, "#{Rails.env}_#{Time.now.strftime('%H')}_00.sql")
    p command = 'mysqldump --opt --skip-add-locks --single-transaction --no-create-db --set-gtid-purged=off ' \
                '--ignore-table=dryad.stash_engine_container_files ' \
                '--ignore-table=dryad.paper_trail_version ' \
                '--ignore-table=dryad.stash_engine_ror_orgs --ignore-table=dryad.stash_engine_curation_stats ' \
                '--ignore-table=dryad.stash_engine_frictionless_reports --ignore-table=dryad.stash_engine_download_tokens ' \
                "-h #{db['host']} -u #{db['username']} -p#{db['password']} #{db['database']} | gzip > #{file}.gz"
    exec command
  end

  desc 'Kill large memory usage passenger processes'
  task kill_bloated_passengers: :environment do
    passenger = Tasks::DevOps::Passenger.new

    passenger.kill_bloated_pids! unless passenger.items_submitting?

    # puts "passenger.status: #{passenger.status}"
    # puts "out: \n #{passenger.stdout}"
    # puts passenger.bloated_pids
    # puts passenger.items_submitting?
  end

  # we really don't want to babysit all of our processes too much and have them re-attempt a few times over days
  desc "Re-enqueue errored Zenodo copies that haven't been tried 3 times"
  task retry_zenodo_errors: :environment do
    puts ''
    puts "Re-enqueuing errored ZenodoCopies in DelayedJob at #{Time.new.utc.iso8601}"
    StashEngine::ZenodoCopy.where('retries < 4').where(state: 'error').order(:resource_id).each do |zc|
      puts "Adding resource_id: #{zc.resource_id}"
      zc.update(state: 'enqueued')
      StashEngine::ZenodoCopyJob.perform_async(zc.resource_id)
    end
  end

  desc 'Lists numbers of long jobs'
  task long_jobs: :environment do
    # note, ignore the supposedly processing items languishing over a week since they're unlikely to really be processing
    repo_enqueued = StashEngine::RepoQueueState.latest_per_resource.where(state: 'enqueued').count
    repo_processing = StashEngine::RepoQueueState.latest_per_resource.where(state: 'processing')
      .where('updated_at > ?', Time.now - 7.days).count
    zenodo_enqueued = StashEngine::ZenodoCopy.where(state: 'enqueued').count
    zenodo_processing = StashEngine::ZenodoCopy.where(state: 'replicating').where('updated_at > ?', Time.now - 7.days).count

    puts ''
    puts "#{repo_enqueued} items in Repo submission queue"
    puts "#{repo_processing} items are being sent to Repo now"
    puts "#{zenodo_enqueued} items in Zenodo-replication queue"
    puts "#{zenodo_processing} items are still being replicated to Zenodo"
  end

  desc 'Re-enqueue deferred Zenodo copy jobs'
  task enqueue_zenodo_deferred: :environment do
    puts 'Re-enqueuing Zenodo replication jobs that were deferred'
    StashEngine::ZenodoCopyJob.enqueue_deferred
    StashEngine::ZenodoSoftwareJob.enqueue_deferred
    StashEngine::ZenodoSuppJob.enqueue_deferred
  end

  # this is for Merritt changes moving the old UC collections into the Dryad collections
  # After things are moved, two things need to happen 1) the tenant config needs to be
  # changed to point to dryad, and 2) this script needs to be run against the text file
  # provided by David Loy in order to update the ARKs in the sword URLs so that downloads
  # and further version submissions work.
  # example: RAILS_ENV="development" bundle exec rake dev_ops:download_uri -- --path /path/to/file.txt
  desc 'Updates database for Merritt ark changes'
  task download_uri: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      exit
    end
    args = Tasks::ArgsParser.parse(:path)

    unless args.path
      puts 'Please put the path to the file to process'
      exit
    end

    Tasks::DevOps::DownloadUri.update_from_file(file_path: args.path)
    puts 'Done'
    exit
  end

  # example: RAILS_ENV="development" bundle exec rake dev_ops:version_into_new_dataset -- --doi string --user_id 10 --tenant_id 20
  desc 'Takes a DOI, user_id (number), tenant_id and copies the latest submitted version into a new dataset for manual submission'
  task version_into_new_dataset: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      exit
    end
    args = Tasks::ArgsParser.parse(:doi, :user_id, :tenant_id)

    if !args.doi || !args.user_id || !args.tenant_id
      puts 'takes DOI, user_id (number from db), tenant_id -- please quote the DOI and do only bare DOI like 10.18737/D7CC8B'
      exit
    end

    # get the identifier
    dryad_id_obj = StashEngine::Identifier.where(identifier: args.doi).first
    unless dryad_id_obj
      puts 'Invalid DOI'
      exit
    end

    # get the the last resource
    last_res = dryad_id_obj.resources.submitted_only.last

    # duplicate the resource
    new_res = last_res.amoeba_dup
    new_res.tenant_id = args.tenant_id
    new_res.identifier_id = nil

    new_res.save

    # Now create new identifier
    my_id = Datacite::DoiGen.mint_id(resource: new_res)
    id_type, id_text = my_id.split(':', 2)
    db_id_obj = StashEngine::Identifier.create(identifier: id_text, identifier_type: id_type.upcase)

    # cleanup some old garbage from merritt-sword and reset user
    new_res.update(identifier_id: db_id_obj.id, user_id: args.user_id, current_editor_id: args.user_id, download_uri: nil, update_uri: nil)

    # update the versions to be version 1, since otherwise it will be version number from old resource
    new_res.stash_version.update(version: 1, merritt_version: 1)

    # update all the files so they can be downloaded from presigned URLs to put into this
    new_res.data_files.present_files.each do |f|
      last_f = StashEngine::DataFile.where(resource_id: last_res.id, upload_file_name: f.upload_file_name).present_files.first
      f.update(url: last_f.merritt_s3_presigned_url, file_state: 'created', status_code: 200)
    end

    # delete any file records for deleted items
    new_res.data_files.deleted_from_version.each(&:destroy!)
    exit
  end

  # We have a lot of junk identifiers without files that actually work since metadata was imported for testing without
  # the files.  This should clean up stuff where a file doesn't load from the repo.
  desc 'Clean datasets not in repo'
  task clean_datasets: :environment do

    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    next if ENV['RAILS_ENV'] == 'production' # should never be run on production

    StashEngine::Identifier.all.each do |ident|
      resource = ident.resources.submitted_only.by_version_desc.first # get last submitted
      next unless resource.present?

      test_file = resource.data_files.present_files.first

      # the preview_file will attempt a download of the first 2k of the file from the repo and returns nil if not able
      if test_file.nil? || test_file.sniff_file(2048, encode: false).nil?
        puts "Removing identifier #{ident}"
        # delete this dataset with no useful files
        puts '  Deleting from SOLR'
        solr = RSolr.connect url: APP_CONFIG.solr_url
        solr.delete_by_query("uuid:\"#{ident}\"")
        solr.commit

        puts '  Removing from the database'
        ident.destroy!
      else
        puts "Identifer #{ident} seems ok"
      end
      sleep 0.5
    end
  end

  # example: RAILS_ENV="development" bundle exec rake dev_ops:destroy_dataset -- --doi 20.18737/D7CC8B
  desc 'Takes a DOI (bare, without doi on front) and destroys it'
  task destroy_dataset: :environment do
    args = Tasks::ArgsParser.parse(:doi)

    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      exit
    end

    unless args.doi
      puts 'Takes a DOI (bare, without doi on front) and destroys it like 10.18737/D7CC8B'
      exit
    end

    identif_str = args.doi

    puts "Are you sure you want to delete #{identif_str}?  (Type 'yes' to proceed)"
    response = $stdin.gets
    exit unless response.strip.casecmp('YES').zero?

    # get identifier
    identifier = StashEngine::Identifier.where(identifier: identif_str).first

    if identifier.nil?
      puts 'The DOI was not found to remove'
      exit
    end

    puts 'Deleting from SOLR'
    solr = RSolr.connect url: APP_CONFIG.solr_url
    solr.delete_by_query("uuid:\"doi:#{identif_str}\"")
    solr.commit

    tenant = identifier.resources.last.tenant
    if tenant.identifier_service.provider == 'ezid'
      puts 'tombstoning EZID'
      ezid_client = Ezid::Client.new(user: tenant.identifier_service.account, password: tenant.identifier_service.password)
      params = { status: 'unavailable | withdrawn' }
      begin
        ezid_client.modify_identifier("doi:#{identif_str}", **params)
      rescue Ezid::IdentifierNotFoundError
        puts "EZID couldn't find identifier to create a tombstone"
      end
    else
      puts 'Please remove access in the DataCite UI -- this functionality may be added later'
    end

    puts "\nYou may need to ask Zenodo to remove the following deposition_ids or DOIs manually"
    identifier.zenodo_copies.order(:deposition_id, :copy_type).each do |zc|
      puts "deposition_id: #{zc.deposition_id}, copy_type: #{zc.copy_type}, doi: #{zc.software_doi || identifier.identifier}"
    end

    puts "\nRemove the item from the repo with url #{identifier.resources.first.download_uri}\n"

    puts "\nRemoving from the database\n"

    identifier.destroy!
  end

  # example: RAILS_ENV="development" bundle exec rake dev_ops:embargo_zenodo -- --resource_id 5 --deposition_id 10 /
  # --date 2024-06-06 --zenodo_copy_id 30
  desc 'Updates database for Merritt ark changes'
  task embargo_zenodo: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      exit
    end

    args = Tasks::ArgsParser.parse(:resource_id, :deposition_id, :date, :zenodo_copy_id)
    if !args.resource_id || !args.deposition_id || !args.date || !args.zenodo_copy_id
      puts 'Add the following arguments after the rake command --resource_id 5 --deposition_id 10 --date 2024-06-06 --zenodo_copy_id 30'
      puts 'The deposition id can be found in the stash_engine_zenodo_copies table'
      exit
    end

    require 'stash/zenodo_replicate/deposit'
    res = StashEngine::Resource.find(args.resource_id)

    dep = Stash::ZenodoReplicate::Deposit.new(resource: res, zc_id: args.zenodo_copy_id)

    resp = dep.get_by_deposition(deposition_id: args.deposition_id)

    meta = resp['metadata']

    meta['access_right'] = 'embargoed'
    meta['embargo_date'] = args.date

    dep.reopen_for_editing

    dep.update_metadata(manual_metadata: meta)

    dep.publish
    exit
  end

  # NOTE: this only downloads the newly uploaded to S3 files since those are the only ones to exist there.
  # The rest that have been previously uploaded are in s#.
  #
  # This creates a directory in the Rails.root named after the resource id and downloads the files into that from S3
  # # example: RAILS_ENV="development" bundle exec rake dev_ops:download_s3 -- --resource_id 5
  desc 'Download the files someone uploaded to S3, should take one argument which is the resource id'
  task download_s3: :environment do
    args = Tasks::ArgsParser.parse(:resource_id)
    resource_id = args.resource_id

    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    unless resource_id
      puts 'Add the following arguments after the rake command --resource_id'
      next
    end

    save_path = Rails.root.join(resource_id.to_s)
    FileUtils.mkdir_p(save_path)

    dl_s3 = Tasks::DevOps::DownloadS3.new(path: save_path)

    StashEngine::DataFile.where(resource_id: resource_id).where(file_state: 'created').each_with_index do |data_file, idx|
      puts "#{idx}  #{data_file.upload_file_name}"
      dl_s3.download(file_obj: data_file)
    end
  end

  desc 'hack resubmit'
  task hack_resubmit: :environment do
    0.upto(200) do
      puts "attempting resubmitting recent errors #{Time.new}"
      resource_ids = StashEngine::RepoQueueState.where(state: 'errored').where(['updated_at > ?', 1.day.ago]).map(&:resource_id)

      resource_ids.each do |res_id|
        states = StashEngine::RepoQueueState.where(resource_id: res_id)
        states[1..].each(&:destroy) # destroy all but the first state in the series
        states.first.update(state: 'rejected_shutting_down') # change info on 1st state
        Submission::ResourcesService.new(@resource_id).trigger_submission # resubmit it
      end
      sleep 300 # wait 5 minutes before checking again
      # note: if you don't leave some time after running the resubmissions, then they don't go through since the request
    end
  end
end
# rubocop:enable Metrics/BlockLength
# :nocov:

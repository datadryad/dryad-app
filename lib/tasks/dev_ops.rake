require 'yaml'
require_relative 'dev_ops/passenger'
require_relative 'dev_ops/download_uri'
require_relative 'dev_ops/download_s3'
require 'rsolr'
require 'ezid/client'
require 'fileutils'

# rubocop:disable Metrics/BlockLength
namespace :dev_ops do

  # use like: bundle exec rake dev_ops:processing RAILS_ENV=development
  desc 'Shows processing submissions'
  task processing: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
    in_process = StashEngine::Resource.joins(:current_resource_state).where("stash_engine_resource_states.resource_state = 'processing'")
    puts "resource_id\tuser_id\tcurrent_status\tupdated at\ttitle" if in_process.count > 0
    in_process.each do |i|
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
      ds_info = Stash::Repo::DatasetInfo.new(i)
      i.update(storage_size: ds_info.dataset_size)
    end
  end

  desc 'fill missing file sizes'
  task fill_file_size: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
    fus = StashEngine::DataFile.where(upload_file_size: [0, nil])
    fus.each do |data_file|
      resource = data_file.resource
      next unless resource && resource.current_resource_state && resource.current_resource_state.resource_state == 'submitted'

      puts "updating resource #{resource.id} & #{resource.identifier}"
      ds_info = Stash::Repo::DatasetInfo.new(resource.identifier)
      data_file.update(upload_file_size: ds_info.file_size(data_file.upload_file_name))
    end
  end

  desc 'Update the description fields to have html content (generated from text)'
  task htmlize: :environment do
    require 'script/htmlize_descriptions'

    puts "Are you sure you want to update desciption text to html in #{Rails.env}?  (Type 'yes' to proceed, 'no' to preview.)"
    response = $stdin.gets
    if response.strip.casecmp('YES').zero?
      StashDatacite::Description.all.each do |desc|
        item = Script::HtmlizeDescriptions.new(desc.description)
        next if item.html? || desc.description.blank?

        out_html = item.text_as_html
        desc.update(description: out_html)
        puts "Updated description id: #{desc.id}"
        puts out_html
        puts ''
      end

    else
      StashDatacite::Description.all.each do |desc|
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
    directory = '/apps/dryad/apps/ui/shared/cron/backups'
    FileUtils.mkdir_p directory
    # YAML.safe_load is preferred by rubocop but it causes the read to fail on `unknown alias 'defaul'`
    # rubocop:disable Security/YAMLLoad
    db = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'database.yml'))).result)[Rails.env]
    # rubocop:enable Security/YAMLLoad
    file = File.join(directory, "#{Rails.env}_#{Time.now.strftime('%H_%M')}.sql")
    p command = 'mysqldump --opt --skip-add-locks --single-transaction --no-create-db ' \
                "-h #{db['host']} -u #{db['username']} -p#{db['password']} #{db['database']} | gzip > #{file}.gz"
    exec command
  end

  desc 'Kill large memory usage passenger processes'
  task kill_bloated_passengers: :environment do
    passenger = DevOps::Passenger.new

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
      StashEngine::ZenodoCopyJob.perform_later(zc.resource_id)
    end
  end

  desc 'Lists numbers of long jobs'
  task long_jobs: :environment do
    # note, ignore the supposedly processing items languishing over a week since they're unlikely to really be processing
    merritt_enqueued = StashEngine::RepoQueueState.latest_per_resource.where(state: 'enqueued').count
    merritt_processing = StashEngine::RepoQueueState.latest_per_resource.where(state: 'processing')
      .where('updated_at > ?', Time.now - 7.days).count
    zenodo_enqueued = StashEngine::ZenodoCopy.where(state: 'enqueued').count
    zenodo_processing = StashEngine::ZenodoCopy.where(state: 'replicating').where('updated_at > ?', Time.now - 7.days).count

    puts ''
    puts "#{merritt_enqueued} items in Merritt submission queue"
    puts "#{merritt_processing} items are being sent to Merritt now"
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
  desc 'Updates database for Merritt ark changes'
  task download_uri: :environment do
    # example command
    # RAILS_ENV="development" bundle exec rake dev_ops:download_uri /path/to/file.txt
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    unless ARGV.length == 2
      puts 'Please put the path to the file to process'
      next
    end

    DevOps::DownloadUri.update_from_file(file_path: ARGV[1])
    puts 'Done'
  end

  desc 'Takes a DOI, user_id (number), tenant_id and copies the latest submitted version into a new dataset for manual submission'
  task version_into_new_dataset: :environment do
    # apparently I have to do this, at least in some cases because arguments to rake are ugly
    # https://www.seancdavis.com/blog/4-ways-to-pass-arguments-to-a-rake-task/

    # rubocop:disable Style/BlockDelimiters
    ARGV.each { |a| task a.to_sym do; end } # see comment above
    # rubocop:enable Style/BlockDelimiters

    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    unless ARGV.length == 4
      puts 'takes DOI, user_id (number from db), tenant_id -- please quote the DOI and do only bare DOI like 10.18737/D7CC8B'
      next
    end

    identif_str = ARGV[1].strip
    user_id = ARGV[2].strip.to_i
    tenant_id = ARGV[3].strip

    # get the identifier
    dryad_id_obj = StashEngine::Identifier.where(identifier: identif_str).first

    # get the the last resource
    last_res = dryad_id_obj.resources.submitted_only.last

    # duplicate the resource
    new_res = last_res.amoeba_dup
    new_res.tenant_id = tenant_id
    new_res.identifier_id = nil

    new_res.save

    # Now create new identifier
    my_id = Stash::Doi::IdGen.mint_id(resource: new_res)
    id_type, id_text = my_id.split(':', 2)
    db_id_obj = StashEngine::Identifier.create(identifier: id_text, identifier_type: id_type.upcase)

    # cleanup some old garbage from merritt-sword and reset user
    new_res.update(identifier_id: db_id_obj.id, user_id: user_id, current_editor_id: user_id, download_uri: nil, update_uri: nil)

    # update the versions to be version 1, since otherwise it will be version number from old resource
    new_res.stash_version.update(version: 1, merritt_version: 1)

    # update all the files so they can be downloaded from presigned URLs from Merritt to put into this
    new_res.data_files.present_files.each do |f|
      last_f = StashEngine::DataFile.where(resource_id: last_res.id, upload_file_name: f.upload_file_name).present_files.first
      f.update(url: last_f.merritt_s3_presigned_url, file_state: 'created', status_code: 200)
    end

    # delete any file records for deleted items
    new_res.data_files.deleted_from_version.each(&:destroy!)
  end

  # We have a lot of junk identifiers without files that actually work since metadata was imported for testing without
  # the files.  This should clean up stuff where a file doesn't load from Merritt.
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

      # the preview_file will attempt a download of the first 2k of the file from Merritt and returns nil if not able
      if test_file.nil? || test_file.preview_file.nil?
        puts "Removing identifier #{ident}"
        # delete this dataset with no useful files
        puts '  Deleting from SOLR'
        solr = RSolr.connect url: Blacklight.connection_config[:url]
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

  desc 'Takes a DOI (bare, without doi on front) and destroys it'
  task destroy_dataset: :environment do
    # apparently I have to do this, at least in some cases because arguments to rake are ugly
    # https://www.seancdavis.com/blog/4-ways-to-pass-arguments-to-a-rake-task/

    # rubocop:disable Style/BlockDelimiters
    ARGV.each { |a| task a.to_sym do; end } # see comment above
    # rubocop:enable Style/BlockDelimiters

    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    unless ARGV.length == 2
      puts 'Takes a DOI (bare, without doi on front) and destroys it like 10.18737/D7CC8B'
      next
    end

    identif_str = ARGV[1].strip

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
    solr = RSolr.connect url: Blacklight.connection_config[:url]
    solr.delete_by_query("uuid:\"doi:#{identif_str}\"")
    solr.commit

    tenant = identifier.resources.last.tenant
    if tenant.identifier_service.provider == 'ezid'
      puts 'tombstoning EZID'
      ezid_client = ::Ezid::Client.new(user: tenant.identifier_service.account, password: tenant.identifier_service.password)
      params = { status: 'unavailable | withdrawn' }
      begin
        ezid_client.modify_identifier("doi:#{identif_str}", params)
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

    puts "\nAsk Merritt to remove the item with url #{identifier.resources.first.download_uri}\n"

    puts "\nRemoving from the database\n"

    identifier.destroy!
  end

  desc 'Updates database for Merritt ark changes'
  task embargo_zenodo: :environment do
    # apparently I have to do this, at least in some cases because arguments to rake are ugly
    # https://www.seancdavis.com/blog/4-ways-to-pass-arguments-to-a-rake-task/

    # rubocop:disable Style/BlockDelimiters
    ARGV.each { |a| task a.to_sym do; end } # see comment above
    # rubocop:enable Style/BlockDelimiters

    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    unless ARGV.length == 5
      puts 'Add the following arguments after the rake command <resource_id> <deposition_id> <yyyy-mm-dd> <zenodo_copy_id>'
      puts 'The deposition id can be found in the stash_engine_zenodo_copies table'
      next
    end

    res_id = ARGV[1].to_s
    dep_id = ARGV[2].to_s
    emb_date = ARGV[3].to_s
    zc_id = ARGV[4].to_s

    require 'stash/zenodo_replicate/deposit'
    res = StashEngine::Resource.find(res_id)

    dep = Stash::ZenodoReplicate::Deposit.new(resource: res, zc_id: zc_id)

    resp = dep.get_by_deposition(deposition_id: dep_id)

    meta = resp['metadata']

    meta['access_right'] = 'embargoed'
    meta['embargo_date'] = emb_date

    dep.reopen_for_editing

    dep.update_metadata(manual_metadata: meta)

    dep.publish
  end

  # NOTE: this only downloads the newly uploaded to S3 files since those are the only ones to exist there.  The rest
  # that have been previously uploaded are in Merritt.
  #
  # This creates a directory in the Rails.root named after the resource id and downloads the files into that from S3
  desc 'Download the files someone uploaded to S3, should take one argument which is the resource id'
  task download_s3: :environment do
    # rubocop:disable Style/BlockDelimiters
    ARGV.each { |a| task a.to_sym do; end } # see comment above
    # rubocop:enable Style/BlockDelimiters

    resource_id = ARGV[1].to_i

    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    unless ARGV.length == 2
      puts 'Add the following arguments after the rake command <resource_id>'
      next
    end

    save_path = Rails.root.join(resource_id.to_s)
    FileUtils.mkdir_p(save_path)

    dl_s3 = DevOps::DownloadS3.new(path: save_path)

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

      resource_ids.each do |res|
        states = StashEngine::RepoQueueState.where(resource_id: res)
        states[1..].each(&:destroy) # destroy all but the first state in the series
        states.first.update(state: 'rejected_shutting_down', hostname: 'uc3-dryadui01x2-prd') # change info on 1st state
        StashEngine.repository.submit(resource_id: res) # resubmit it
      end
      sleep 300 # wait 5 minutes before checking again
      # note: if you don't leave some time after running the resubmissions, then they don't go through since the request
      # processes that the StashEngine.repository class creates get killed if this task exits immediately.
      #
      # The StashEngine.repository class it uses is a different instance than the one that runs inside the UI processes.
      #
      # We really probably would be better off moving the submissions outside the UI processes. Maybe when we rework to
      # use a Merritt API instead of sword for submissions.
    end
  end
end
# rubocop:enable Metrics/BlockLength

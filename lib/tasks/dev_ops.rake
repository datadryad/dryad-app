require 'yaml'
require_relative 'dev_ops/passenger'
require_relative 'dev_ops/download_uri'

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
    fus = StashEngine::FileUpload.where(upload_file_size: [0, nil])
    fus.each do |file_upload|
      resource = file_upload.resource
      next unless resource && resource.current_resource_state && resource.current_resource_state.resource_state == 'submitted'

      puts "updating resource #{resource.id} & #{resource.identifier}"
      ds_info = Stash::Repo::DatasetInfo.new(resource.identifier)
      file_upload.update(upload_file_size: ds_info.file_size(file_upload.upload_file_name))
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
    FileUtils.mkdir directory unless File.exist?(directory)
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
  end

  desc 'Gets Counter token for submitting a report'
  task get_counter_token: :environment do
    puts APP_CONFIG[:counter][:token]
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
end
# rubocop:enable Metrics/BlockLength

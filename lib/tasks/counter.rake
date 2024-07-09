require 'net/scp'
require_relative 'counter/validate_file'
require_relative 'counter/log_combiner'
require_relative 'counter/json_stats'

namespace :counter do
  # example: RAILS_ENV=development bundle exec rake counter:combine_files -- --log_directory /user/me/dir --scp_hosts host1,host2
  desc 'get and combine files from the other servers'
  task :combine_files do
    args = Tasks::ArgsParser.parse(:log_directory, :scp_hosts)
    lc = Tasks::Counter::LogCombiner.new(log_directory: args.log_directory, scp_hosts: args.scp_hosts.to_s.split(','),
                                         scp_path: args.log_directory)
    lc.copy_missing_files
    lc.combine_logs
    exit
  end

  # example: RAILS_ENV=development bundle exec rake counter:remove_old_logs -- --log_directory /user/me/dir --scp_hosts host1,host2
  desc 'remove log files we are not keeping because of our privacy policy'
  task :remove_old_logs do
    args = Tasks::ArgsParser.parse(:log_directory, :scp_hosts)
    lc = Tasks::Counter::LogCombiner.new(log_directory: args.log_directory, scp_hosts: args.scp_hosts.to_s.split(','),
                                         scp_path: args.log_directory)
    lc.remove_old_logs(days_old: 60)
    lc.remove_old_logs_remote(days_old: 60)
    exit
  end

  # example: rails/rake counter:validate_logs -- --files file_name_1,file_name_2
  desc 'validate counter logs format (filenames come after rake task)'
  task :validate_logs do
    args = Tasks::ArgsParser.parse(:files)
    unless args.files
      puts 'Please enter the filenames of files to validate, separated by comma'
      exit
    end

    args.files.split(',').each do |filename|
      puts "Validating #{filename}"
      cv = Tasks::Counter::ValidateFile.new(filename: filename)
      cv.validate_file
      puts ''
    end
    exit # makes the arguments not be interpreted as other rake tasks
  end # end of task

  # example: RAILS_ENV=production bundle exec rake counter:cop_manual -- --json_directory /user/me/json-reports
  desc 'manually populate CoP stats from json files'
  task cop_manual: :environment do
    # this keeps the output from buffering forever until a chunk fills so that output is timely
    $stdout.sync = true
    args = Tasks::ArgsParser.parse(:json_directory)
    puts "JSON_DIRECTORY is #{args.json_directory}"

    js = Tasks::Counter::JsonStats.new
    Dir.glob(File.join(args.json_directory, '????-??.json')).each do |f|
      puts f
      js.update_stats(f)
    end
    js.update_database
    exit
  end

  desc 'pre-populate our COUNTER CoP stats from datacite hub'
  task cop_populate: :environment do
    $stdout.sync = true

    puts "Starting run to update COUNTER CoP stats from DataCite hub at #{Time.new}"
    # we only need stats for published and embargoed items, though there may be a few views from preview links before
    count = StashEngine::Identifier.where(pub_state: %i[published embargoed]).count
    StashEngine::Identifier.where(pub_state: %i[published embargoed]).find_each.with_index do |identifier, idx|
      puts "Updated #{idx + 1}/#{count}" if (idx + 1) % 10 == 0
      cs = identifier.counter_stat
      cs.update_if_necessary # does update if not updated in this calendar week
      sleep 1 # to avoid overloading DataCite hub
    end
  end

  # this allows stats to be zeroed without destroying citation count which happens in another process and means that our
  # stats can be manually rebuilt from our full JSON stat files which DataCite doesn't accept for unknown reasons.
  desc "zero out table of cached Counter stats without affecting citation count which doesn't come from counter"
  task clear_cache: :environment do
    StashEngine::CounterStat.in_batches.update_all(unique_investigation_count: 0, unique_request_count: 0)
  end

  desc 'task to populate in citation information that has not been cached'
  task populate_citations: :environment do
    puts "Run to update citations at #{Time.new}"
    count = StashEngine::Identifier.where(pub_state: %i[published embargoed]).count

    StashEngine::Identifier.where(pub_state: %i[published embargoed]).find_each.with_index do |identifier, idx|
      puts "Updated #{idx + 1}/#{count}" if (idx + 1) % 100 == 0

      counter_stat = identifier.counter_stat
      next if counter_stat.citation_updated > 30.days.ago # only do this expensive operation once a month, so skip if it's been checked lately

      # identifier.citations automatically checks and caches new ones as needed
      citations = identifier.citations

      counter_stat.citation_count = citations.length
      counter_stat.citation_updated = Time.new
      counter_stat.save!
      puts "Completed populating citations at #{Time.new.utc.iso8601}"
    end
  end

  # example: RAILS_ENV=development bundle exec rake counter:test_env -- --log_directory /user/me/dir --scp_hosts host1,host2
  desc 'test that environment is passed in'
  task :test_env do
    args = Tasks::ArgsParser.parse(:log_directory, :scp_hosts)

    puts "LOG_DIRECTORY is set as #{args.log_directory}" if args.log_directory
    puts "SCP_HOSTS are set as #{args.scp_hosts.split(',')}" if args.scp_hosts
    puts "note: in order to scp, you must add this server's public key to the authorized keys for the server you want to copy from"
    exit
  end

  # example: RAILS_ENV=development bundle exec rake counter:datacite_pusher -- --report_dir /user/me/dir --report_ids true
  desc 'look for missing reports and force send them to datacite'
  task datacite_pusher: :environment do
    # something like this will get a list of reports that have been sent to DataCite and their IDs
    # RAILS_ENV=production bundle exec rails counter:datacite_pusher --report_dir /my/report/dir --report_ids true
    #
    # for typical monthly run of submitting missing and forcing last month
    # RAILS_ENV=production bundle exec rails counter:datacite_pusher --report_dir /my/report/dir --force_submission 2021-11
    $stdout.sync = true

    require_relative '../../script/stash/counter-uploader/submitted_reports'
    require_relative '../../script/stash/counter-uploader/uploader'
    require_relative '../../script/stash/counter-uploader/utility_methods'
    args = Tasks::ArgsParser.parse(:report_dir, :force_submission, :report_ids)

    if args.report_dir.blank?
      puts 'You must set an environment variable for REPORT_DIR to upload to DataCite.'
      puts 'Optional environment variables:'
      puts "\t--report_ids -- if set, only reports the yyyy-mm and ids that have been sent to DataCite."
      puts "\t--force_submission may be set with a comma separated list of yyyy-mm values and those reports"
      puts "\twill be sent again, even if they appear to have already been submitted successfully."
      next # this is like return but from a rake task
    end

    # setup variables needed
    report_directory = args.report_dir
    # if --report_dir is set then just report the IDs for our reports
    # if --force_submission is set with comma separated yyyy-mm values then those reports will be
    # submitted again, even if they already appear to have been submitted

    force_list = UtilityMethods.force_submission_list

    # retrieve all the information about already submitted reports from DataCite
    submitted_reports = SubmittedReports.new
    submitted_reports.process_reports

    # display submitted report info and exit if that option was chosen
    if args.report_ids
      UtilityMethods.output_report_table(submitted_reports)
      exit # ie exit from rake task
    end

    # get the json files we have non-zero reports for and are in the correct filename format
    json_files = Dir.glob(File.join(report_directory, '*.json'))
    json_files.keep_if { |f| f.match(/\d{4}-\d{2}.json$/) && File.size(f) > 0 }
    json_files.sort!

    # go through our report files and try to submit unsubmitted/problem ones (and any you want to force submission for)
    json_files.each do |json_file|
      month_year = File.basename(json_file, '.json')
      submitted_report = submitted_reports.reports[month_year]
      if UtilityMethods.needs_submission?(month_year: month_year, report_info: submitted_report, report_directory: report_directory,
                                          force_list: force_list)
        puts "adding or updating #{month_year} with #{submitted_report&.pages || 'unsubmitted'} pages"

        report_id = (submitted_report.nil? ? nil : submitted_report.id)
        uploader = Uploader.new(report_id: report_id, file_name: json_file)
        token = uploader.process
        puts "report submitted with id #{token}\n\n"
      else
        puts "skipping #{submitted_report.year_month} with #{submitted_report.pages} pages\n\n"
      end
    end
  end
end

require 'net/scp'
require_relative 'counter/validate_file'
require_relative 'counter/log_combiner'
require_relative 'counter/json_stats'
namespace :counter do

  desc 'get and combine files from the other servers'
  task :combine_files do
    lc = Counter::LogCombiner.new(log_directory: ENV.fetch('LOG_DIRECTORY', nil), scp_hosts: ENV['SCP_HOSTS'].split,
                                  scp_path: ENV.fetch('LOG_DIRECTORY', nil))
    lc.copy_missing_files
    lc.combine_logs
  end

  desc 'remove log files we are not keeping because of our privacy policy'
  task :remove_old_logs do
    lc = Counter::LogCombiner.new(log_directory: ENV.fetch('LOG_DIRECTORY', nil), scp_hosts: ENV['SCP_HOSTS'].split,
                                  scp_path: ENV.fetch('LOG_DIRECTORY', nil))
    lc.remove_old_logs(days_old: 60)
    lc.remove_old_logs_remote(days_old: 60)
  end

  desc 'validate counter logs format (filenames come after rake task)'
  task :validate_logs do
    if ARGV.length == 1
      puts 'Please enter the filenames of files to validate, separated by spaces'
      exit
    end
    ARGV.each do |filename|
      next if filename == 'counter:validate_logs'

      puts "Validating #{filename}"
      cv = Counter::ValidateFile.new(filename: filename)
      cv.validate_file
      puts ''
    end
    exit # makes the arguments not be interpreted as other rake tasks
  end # end of task

  # example: JSON_DIRECTORY="/user/me/json-reports" RAILS_ENV=production bundle exec rake counter:cop_manual
  desc 'manually populate CoP stats from json files'
  task cop_manual: :environment do
    # this keeps the output from buffering forever until a chunk fills so that output is timely
    $stdout.sync = true
    puts "JSON_DIRECTORY is #{ENV.fetch('JSON_DIRECTORY', nil)}"

    js = JsonStats.new
    Dir.glob(File.join(ENV.fetch('JSON_DIRECTORY', nil), '????-??.json')).sort.each do |f|
      puts f
      js.update_stats(f)
    end
    js.update_database
  end

  # this allows stats to be zeroed without destroying citation count which happens in another process and means that our
  # stats can be manually rebuilt from our full JSON stat files which DataCite doesn't accept for unknown reasons.
  desc "zero out table of cached Counter stats without affecting citation count which doesn't come from counter"
  task clear_cache: :environment do
    StashEngine::CounterStat.update_all(unique_investigation_count: 0, unique_request_count: 0)
  end

  desc 'task to populate in citation information that has not been cached'
  task populate_citations: :environment do
    puts "Run to update citations at #{Time.new}"
    identifiers = StashEngine::Identifier.where(pub_state: %i[published embargoed])

    identifiers.each_with_index do |identifier, idx|
      puts "Updated #{idx + 1}/#{identifiers.length}" if (idx + 1) % 100 == 0

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

  desc 'test that environment is passed in'
  task :test_env do
    puts "LOG_DIRECTORY is set as #{ENV['LOG_DIRECTORY']}" if ENV['LOG_DIRECTORY']
    puts "SCP_HOSTS are set as #{ENV['SCP_HOSTS'].split}" if ENV['SCP_HOSTS']
    puts "note: in order to scp, you must add this server's public key to the authorized keys for the server you want to copy from"
  end

  desc 'look for missing reports and force send them to datacite'
  task datacite_pusher: :environment do
    # something like this will get a list of reports that have been sent to DataCite and their IDs
    # RAILS_ENV=production REPORT_DIR="/my/report/dir" REPORT_IDS=true bundle exec rails counter:datacite_pusher
    #
    # for typical monthly run of submitting missing and forcing last month
    # RAILS_ENV=production REPORT_DIR="/my/report/dir" FORCE_SUBMISSION="2021-11" bundle exec rails counter:datacite_pusher
    $stdout.sync = true

    require_relative '../../../script/counter-uploader/submitted_reports'
    require_relative '../../../script/counter-uploader/uploader'
    require_relative '../../../script/counter-uploader/utility_methods'

    if ENV['REPORT_DIR'].blank?
      puts 'You must set an environment varaiable for REPORT_DIR to upload to DataCite.'
      puts 'Optional environment variables:'
      puts "\tREPORT_IDS -- if set, only reports the yyyy-mm and ids that have been sent to DataCite."
      puts "\tFORCE_SUBMISSION may be set with a comma separated list of yyyy-mm values and those reports"
      puts "\twill be sent again, even if they appear to have already been submitted successfully."
      next # this is like return but from a rake task
    end

    # setup variables needed
    report_directory = ENV.fetch('REPORT_DIR', nil)
    # if ENV['REPORT_IDS'] is set then just report the IDs for our reports
    # if ENV['FORCE_SUBMISSION'] is set with comma separated yyyy-mm values then those reports will be
    # submitted again, even if they already appear to have been submitted

    force_list = UtilityMethods.force_submission_list

    # retrieve all the information about already submitted reports from DataCite
    submitted_reports = SubmittedReports.new
    submitted_reports.process_reports

    # display submitted report info and exit if that option was chosen
    if ENV['REPORT_IDS']
      UtilityMethods.output_report_table(submitted_reports)
      next # ie exit from rake task
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

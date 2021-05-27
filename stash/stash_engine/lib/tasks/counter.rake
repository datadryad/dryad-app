require 'net/scp'
require_relative 'counter/validate_file'
require_relative 'counter/log_combiner'
require_relative 'counter/json_stats'
namespace :counter do

  desc 'get and combine files from the other servers'
  task :combine_files do
    lc = Counter::LogCombiner.new(log_directory: ENV['LOG_DIRECTORY'], scp_hosts: ENV['SCP_HOSTS'].split(' '), scp_path: ENV['LOG_DIRECTORY'])
    lc.copy_missing_files
    lc.combine_logs
  end

  desc 'remove log files we are not keeping because of our privacy policy'
  task :remove_old_logs do
    lc = Counter::LogCombiner.new(log_directory: ENV['LOG_DIRECTORY'], scp_hosts: ENV['SCP_HOSTS'].split(' '), scp_path: ENV['LOG_DIRECTORY'])
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
    puts "JSON_DIRECTORY is #{ENV['JSON_DIRECTORY']}"

    js = JsonStats.new
    Dir.glob(File.join(ENV['JSON_DIRECTORY'], '????-??.json')).sort.each do |f|
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
    puts "SCP_HOSTS are set as #{ENV['SCP_HOSTS'].split(' ')}" if ENV['SCP_HOSTS']
    puts "note: in order to scp, you must add this server's public key to the authorized keys for the server you want to copy from"
  end
end

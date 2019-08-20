require 'net/scp'
require_relative 'counter/validate_file'
require_relative 'counter/log_combiner'

# rubocop:disable Metrics/BlockLength
namespace :counter do
  LOG_DIRECTORY = '/apps/dryad/apps/ui/current/log'.freeze
  SCP_HOSTS = ['uc3-dryaduix2-stg-2c.cdlib.org'].freeze
  PRIMARY_FN_PATTERN = /counter_\d{4}-\d{2}-\d{2}.log/

  desc 'get and combine files from the other servers'
  task :combine_files do
    lc = Counter::LogCombiner.new(log_directory: LOG_DIRECTORY, scp_hosts: SCP_HOSTS, scp_path: LOG_DIRECTORY)
    lc.copy_missing_files
    lc.combine_logs
  end

  desc 'remove log files we are not keeping because of our privacy policy'
  task :remove_old_logs do
    lc = Counter::LogCombiner.new(log_directory: LOG_DIRECTORY, scp_hosts: SCP_HOSTS, scp_path: LOG_DIRECTORY)
    lc.remove_old_logs(days_old: 60)
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
end
# rubocop:enable Metrics/BlockLength

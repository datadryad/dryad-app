require 'net/scp'
require_relative 'counter/validate_file'
require_relative 'counter/log_combiner'

# rubocop:disable Metrics/BlockLength
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

  desc 'test environment is passed in'
  task :test_env do
    puts "LOG_DIRECTORY is set as #{ENV['LOG_DIRECTORY']}" if ENV['LOG_DIRECTORY']
    puts "SCP_HOSTS are set as #{ENV['SCP_HOSTS'].split(' ')}" if ENV['SCP_HOSTS']
    puts "note: in order to scp, you must add this server's public key to the authorized keys for the server you want to copy from"
  end
end
# rubocop:enable Metrics/BlockLength

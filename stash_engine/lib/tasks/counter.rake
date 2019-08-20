require 'byebug'
require 'net/scp'
require_relative 'counter/validate_file'
require_relative 'counter/log_combiner'

namespace :counter do
  LOG_DIRECTORY = '/Users/sfisher/workspace/direct-to-cdl-dryad/dryad/log'.freeze
  SCP_HOSTS = ['uc3-dryaduix2-stg-2c.cdlib.org'].freeze
  SCP_PATH = '/apps/dryad/apps/ui/current/log'.freeze
  PRIMARY_FN_PATTERN = /counter_\d{4}-\d{2}-\d{2}.log/

  desc 'get and combine files from the other servers'
  task :combine_files do
    lc = Counter::LogCombiner.new(log_directory: LOG_DIRECTORY, scp_hosts: SCP_HOSTS, scp_path: SCP_PATH)
    lc.copy_missing_files
    lc.combine_logs
  end

  desc 'get and combine files from the other servers'
  task :remove_old_logs do
    lc = Counter::LogCombiner.new(log_directory: LOG_DIRECTORY, scp_hosts: SCP_HOSTS, scp_path: SCP_PATH)
    lc.remove_old_logs(days_old: 60)
  end

  desc 'get and combine files from the other servers'
  task :combine_filesss do
    Dir.chdir(LOG_DIRECTORY) do

      filenames = Dir.glob('*.log')
      counter_filenames = filenames.map { |fn| File.basename(fn) }.keep_if { |fn| fn.match(PRIMARY_FN_PATTERN) }
      counter_filenames.delete(Time.new.strftime('counter_%Y-%m-%d.log'))
      counter_filenames.sort!

      # this looks complicated, but it just produces a hash like the following of what files exist
      # {"counter_2019-08-01.log"=>{0=>false, :combined_file=>false},
      # "counter_2019-08-02.log"=>{0=>true, :combined_file=>true} }.
      # The numbers are other servers in the cluster
      outhash = counter_filenames.map do |x|
        [x,
         SCP_HOSTS.map.with_index { |_v, idx| [idx, File.exist?("#{x}_#{idx}")] }.to_h
           .merge(combined_file: File.exist?("#{x}_combined"))]
      end.to_h

      # go through files and copy and combine them
      outhash.each do |f, v|
        bad_scp = false

        # copy other server's files over if possible
        v.each_pair do |k2, v2|
          next unless k2.class == Integer
          begin
            if v2 == false
              puts "downloading #{f}"
              Net::SCP.download!(SCP_HOSTS[k2], 'dryad', File.join(SCP_PATH, f), "#{f}_#{k2}")
            end
          rescue Net::SCP::Error => e
            raise e unless e.to_s.include?('No such file or directory')
            puts "Skipping #{f}: file doesn't exist on secondary server"
            bad_scp = true
            break
          end
        end

        # sort and combine logs if possible
        next if v[:combined_file] || bad_scp
        puts "combining files to #{f}_combined"
        other_files = 0.upto(SCP_HOSTS.length - 1).map { |i| "#{f}_#{i}" }.join(' ')
        `cat #{f} #{other_files} | sort > #{f}_combined` # now combine & sort them in linux
      end
    end # end of working inside directory
  end # end of task

  desc 'cleanup old logs'
  task :cleanup_logs do

  end # end of task

  desc 'validate log filenames (that come after rake task)'
  task :validate_logs do
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

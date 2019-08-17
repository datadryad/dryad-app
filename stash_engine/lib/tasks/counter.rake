require 'byebug'
require 'net/scp'

namespace :counter do
  LOG_DIRECTORY = '/Users/sfisher/workspace/direct-to-cdl-dryad/dryad/log'.freeze
  SCP_HOSTS = ['uc3-dryaduix2-stg-2c.cdlib.org'].freeze
  SCP_PATH = '/apps/dryad/apps/ui/current/log'.freeze
  PRIMARY_FN_PATTERN = /counter_\d{4}-\d{2}-\d{2}.log/

  desc 'get and combine files from the other servers'
  task :combine_files do
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

      # go through fils and copy and combine them
      outhash.each do |f, v|
        bad_scp = false

        # copy other server's files over if possible
        v.each_pair do |k2, v2|
          if k2.class == Integer
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
        end

        # sort and combine logs if possible
        next if v[:combined_file] || bad_scp
        puts "combining files to #{f}_combined"
        other_files = 0.upto(SCP_HOSTS.length - 1).map{|i| "#{f}_#{i}" }.join(' ')
        `cat #{f} #{other_files} | sort > #{f}_combined` # now combine & sort them in linux
      end
    end # end of working inside directory

    desc 'cleanup old logs'
    task :cleanup_logs do

    end
  end
end

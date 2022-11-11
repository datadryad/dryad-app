require 'net/scp'
require 'time'

module Tasks
  module Counter
    class LogCombiner

      USERNAME = 'dryad'.freeze
      PRIMARY_FN_PATTERN = /^counter_\d{4}-\d{2}-\d{2}.log$/.freeze
      ANY_LOG_FN_PATTERN = /^counter_(\d{4})-(\d{2})-(\d{2}).log(|_\d{1}|_combined)$/.freeze

      def initialize(log_directory:, scp_hosts:, scp_path:)
        @log_directory = log_directory
        @scp_hosts = scp_hosts
        @scp_path = scp_path

        Dir.chdir(@log_directory) do
          filenames = Dir.glob('*.log')
          @primary_filenames = filenames.map { |fn| File.basename(fn) }.keep_if { |fn| fn.match(PRIMARY_FN_PATTERN) }
          @primary_filenames.delete(Time.new.strftime('counter_%Y-%m-%d.log')) # remove today's file, not done yet
          @primary_filenames.sort!
        end
      end

      def copy_missing_files
        Dir.chdir(@log_directory) do
          @primary_filenames.each do |fn|
            @scp_hosts.each_with_index do |host, idx|
              next if File.exist?("#{fn}_#{idx}")

              scp_file(filename: fn, host: host, dest_file: "#{fn}_#{idx}")
            end
          end
        end
      end

      def combine_logs
        Dir.chdir(@log_directory) do
          @primary_filenames.each do |fn|
            next if File.exist?("#{fn}_combined")

            filenames = Dir.glob("#{fn}_[0-9]").join(' ') # assumes no more than 11 UI workers
            `cat #{fn} #{filenames} | sort > #{fn}_combined`
            puts "combined: #{fn} #{filenames} -> #{fn}_combined"
          end
        end
      end

      def remove_old_logs(days_old: 60)
        Dir.chdir(@log_directory) do
          log_filenames = Dir.glob('*.log*').map { |fn| File.basename(fn) }.keep_if { |fn| fn.match(ANY_LOG_FN_PATTERN) }
          log_filenames.each do |fn|
            m = ANY_LOG_FN_PATTERN.match(fn)
            log_date = Time.new(m[1], m[2], m[3])
            if log_date < Time.new - days_old.days
              File.delete(fn)
              puts "Deleted #{fn}"
            end
          end
        end
      end

      def remove_old_logs_remote(days_old: 60)
        # ssh dryad@uc3-dryaduix2-prd-2c.cdlib.org "rm -f /apps/dryad/apps/ui/current/log/counter_2020-09-01.log"
        @scp_hosts.each do |host|
          log_filenames = `ssh #{USERNAME}@#{host} "cd /apps/dryad/apps/ui/current/log/; ls counter_*.log -1a"`.split("\n")
          log_filenames.each do |fn|
            m = ANY_LOG_FN_PATTERN.match(fn)
            log_date = Time.new(m[1], m[2], m[3])
            if log_date < Time.new - days_old.days
              `ssh #{USERNAME}@#{host} "rm -f /apps/dryad/apps/ui/current/log/#{fn}"`
              puts "Deleted #{fn}"
            end
          end
        end
      end

      # --- Private methods below ---

      private

      def scp_file(filename:, host:, dest_file:)
        Net::SCP.download!(host, USERNAME, File.join(@scp_path, filename), dest_file)
        puts "downloaded #{host}:#{filename}"
      rescue Net::SCP::Error => e
        raise e unless e.to_s.include?('No such file or directory')

        puts "Skipped downloading #{host}:#{filename} file doesn't exist on secondary server"
      end
    end
  end
end

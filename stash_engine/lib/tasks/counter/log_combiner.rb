require 'net/scp'

module Counter
  class LogCombiner

    USERNAME = 'dryad'.freeze

    def initialize(log_directory:, scp_hosts:, scp_path:)
      @log_directory = log_directory
      @scp_hosts = scp_hosts
      @scp_path = scp_path
      @primary_fn_pattern = /counter_\d{4}-\d{2}-\d{2}.log/

      Dir.chdir(@log_directory) do
        filenames = Dir.glob('*.log')
        @primary_filenames = filenames.map {|fn| File.basename(fn)}.keep_if {|fn| fn.match(@primary_fn_pattern)}
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

          filenames = Dir.glob("#{fn}_[0-9]").join(' ')  # assumes no more than 11 UI workers
          `cat #{fn} #{filenames} | sort > #{fn}_combined`
          puts "combined: #{fn} #{filenames} -> #{fn}_combined"
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
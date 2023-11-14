# :nocov:
require 'open3'
require 'byebug'

module Tasks
  module DevOps
    class Passenger

      attr_reader :status, :stdout

      BLOATED_MB = 600

      def initialize
        @stdout, @stderr, @status = Open3.capture3('passenger-status')
        @bloated_pids = []
      end

      def not_running?
        @stderr.include?("Phusion Passenger doesn't seem to be running")
      end

      def bloated_pids
        # return (empty) array if not running or return array it is already cached with bloated pids
        return @bloated_pids if not_running? || @bloated_pids.length.positive?

        process_sections = @stdout.split('* PID: ')
        process_sections = process_sections[1..] # the second to the last of the split sections

        process_sections.each do |section|
          matches = section.match(/^(\d+).+Memory *: *(\S+)/m)
          pid = matches[1]
          memory = 0
          memory = matches[2].to_i if matches[2]&.end_with?('M')
          memory = matches[2].to_i * 1000 if matches[2]&.end_with?('G')
          @bloated_pids.push(pid) if memory > BLOATED_MB
        end
        @bloated_pids
      end
      # rubocop:enable

      def kill_bloated_pids!
        bloated_pids.each do |my_pid|
          `kill #{my_pid}`
        end
      end

      def items_submitting?
        StashEngine::RepoQueueState.latest_per_resource.where(state: 'processing')
          .where(hostname: StashEngine.repository.class.hostname).count.positive?
      end

    end
  end
end
# :nocov:

require 'fileutils'
# the notifier was logging to /dryad/apps/ui/shared/cron/logs/stash-notifier.log. Still the correct place?
namespace :merritt_status do

  desc 'Checks for processing items that have now finished and can have state updated'
  task update: :environment do

    # on servers, the log directory is shared across deployment versions, so is a good place to put the logs and also pid file
    log_file = Rails.root.join('log', 'merritt_status_updater.log')
    pid_file = Rails.root.join('tmp', 'pids', 'merritt_status_updater.pid')
    # use something like "kill -15 `cat my/path/to/tmp/pids/merritt_status_updater.pid`" in bash script to kill this.
    # Using kill -9 doesn't give chance to shutdown and clean up

    $stdout.sync = true
    Rails.logger = Logger.new(log_file)

    if File.exist?(pid_file)
      Rails.logger.error('PID file already exists for tmp/pids/merritt_status_updater.pid. Is another copy still running?')
      abort('PID file already exists for tmp/pids/merritt_status_updater.pid. Is another copy still running?')
    end

    File.write(pid_file, Process.pid)

    Signal.trap('INT') { throw :sigint }
    Signal.trap('TERM') { throw :sigint }

    # get pid with Process.pid

    unless ENV['RAILS_ENV']
      Rails.logger.error('RAILS_ENV must be explicitly set before running this task')
      abort('RAILS_ENV must be explicitly set before running this task')
    end

    Rails.logger.info("Starting Merritt status submission updater for environment #{ENV.fetch('RAILS_ENV', nil)}")

    catch(:sigint) do
      loop do
        Rails.logger.info('Starting round of processing')
        StashEngine::RepoQueueState.latest_per_resource.where(state: %w[processing provisional_complete]).each do |queue_state|
          if queue_state.possibly_set_as_completed
            Rails.logger.info("  Resource #{queue_state.resource_id} available in Merritt")
          elsif queue_state.updated_at < 1.day.ago # older than 1 day ago
            Rails.logger.info("  Resource #{queue_state.resource_id} has been processing for more than a day, so marking as errored")
            StashEngine::RepoQueueState.create(resource_id: queue_state.resource_id, state: 'errored')
            exception = StandardError.new("item has been processing for more than a day, so marking as errored")
            exception.set_backtrace(caller)
            StashEngine::UserMailer.error_report(queue_state.resource, exception).deliver_now
          else
            Rails.logger.info("  Resource #{queue_state.resource_id} not yet available")
          end
        end
        Rails.logger.info('Ending round of processing')
        sleep 30
      end
    end

    Rails.logger.info("Shutting down Merritt status updater for environment #{ENV.fetch('RAILS_ENV', nil)}")
    FileUtils.rm_f(pid_file)
  end
end

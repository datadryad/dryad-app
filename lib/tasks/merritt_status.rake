# the notifier was logging to /dryad/apps/ui/shared/cron/logs/stash-notifier.log. Still the correct place?
namespace :merritt_status do

  desc 'Checks for processing items that have now finished and can have state updated'
  task update: :environment do

    # on servers, the log directory is shared across deployment versions, so is a good place to put the logs and also pid file
    log_file = Rails.root.join('log', 'merritt_status_updater.log')
    pid_file = Rails.root.join('log', 'merritt_status_updater.pid')
    # use something like "kill -15 `cat my/path/to/log/merritt_status_updater.pid`" in bash script to kill this.
    # Using kill -9 doesn't give chance to shutdown and clean up

    $stdout.sync = true
    Rails.logger = Logger.new(log_file)

    if File.exist?(pid_file)
      Rails.logger.error('PID file already exists for log/merritt_status_updater.pid. Is another copy still running?')
      abort('PID file already exists for log/merritt_status_updater.pid. Is another copy still running?')
    end

    File.open(pid_file, 'w').write(Process.pid)

    Signal.trap('INT') {throw :sigint }
    Signal.trap('TERM') { throw :sigint }

    # get pid with Process.pid

    unless ENV['RAILS_ENV']
      Rails.logger.error('RAILS_ENV must be explicitly set before running this task')
      abort('RAILS_ENV must be explicitly set before running this task')
    end

    Rails.logger.info("Starting Merritt status submission updater for environment #{ENV['RAILS_ENV']}")

    catch(:sigint) do
      while true do
        Rails.logger.info("Starting round of processing")
        StashEngine::RepoQueueState.latest_per_resource.where(state: 'processing') do |queue_state|
          if queue_state.available_in_merritt?
            Rails.logger.info("  Resource #{queue_state.resource_id} available in Merritt")
            # update all required things for making it complete
          else
            Rails.logger.info("  Resource #{queue_state.resource_id} not yet available")
          end
        end
        Rails.logger.info("Ending round of processing")
        sleep 30
      end
    end

    Rails.logger.info("Shutting down Merritt status updater for environment #{ENV['RAILS_ENV']}")
    File.delete(pid_file) if File.exist?(pid_file)
  end
end
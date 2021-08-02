require_relative '../../stash/stash-notifier/app/config'
require_relative '../../stash/stash-notifier/app/state'
require 'byebug'
namespace :notifier do

  desc 'run the notifier'
  task :execute do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    $stdout.sync = true

    Config.initializer(environment: (ENV['RAILS_ENV'] || 'development'), logger_std_out: true)

    State.create_pid

    Config.logger.info("Starting notifier run for #{Config.environment} environment")

    State.ensure_statefile

    begin
      # get records for each set and time range
      State.sets.each do |set|

        Config.logger.info("trying #{set.name}")
        set.retry_errored_dryad_notifications
        set.notify_dryad

        # If something has been retried every 5 minutes for 30 days and Dryad doesn't know about it, then it was probably deleted
        # from Dryad and not from Merritt and it's time to stop retrying.  We have logs of this stuff if people care to clean up.
        set.clean_retry_items!(days: 30)

        # save the state to the file after each set has run
        State.save_sets_state
      rescue HTTPClient::TimeoutError, HTTPClient::BadResponseError => e
        Config.logger.error("Timeout error for set #{set.name}\n#{e}\n#{e.backtrace.join("\n")}")
      end
    ensure
      Config.logger.info("Finished notifier run for #{Config.environment} environment\n")
      State.remove_pid
    end
  end
end

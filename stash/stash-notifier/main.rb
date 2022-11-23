#!/usr/bin/env ruby

# This keeps the buffer from waiting to output and should synchronize output so it is immediately flushed.
# I hope this also works with the logger stuff, though I don't see any reason why it wouldn't.
$stdout.sync = true

Dir.chdir(__dir__) # gets bundler.require(:default) working from any directory

require 'rubygems'
require 'bundler/setup'
Dir[File.join(__dir__, 'app', '*.rb')].each { |file| require file }
require 'active_support/core_ext/object/to_query'

Bundler.require(:default)

Config.initializer(environment: (ENV['STASH_ENV'] || 'development'), logger_std_out: ENV['NOTIFIER_OUTPUT'] == 'stdout')

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
    Config.logger.error("Timeout error for set #{set.name}\n#{e}\n#{e.full_message}")
  end
ensure
  Config.logger.info("Finished notifier run for #{Config.environment} environment\n")
  State.remove_pid
end

#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
Dir[File.join(__dir__, 'app', '*.rb')].each { |file| require file }
require 'active_support/core_ext/object/to_query'

Bundler.require(:default)

Config.initialize(environment: ENV['RAILS_ENV'] || 'development')

State.create_pid

Config.logger.info("Starting notifier run for #{Config.environment} environment")

State.ensure_statefile

# get records for each set and time range
State.sets.each do |set|
  set.retry_errored_dryad_notifications
  set.notify_dryad

  # save the state to the file after each set has run
  State.save_sets_state
end

Config.logger.info("Finished notifier run for #{Config.environment} environment\n\n")

State.remove_pid
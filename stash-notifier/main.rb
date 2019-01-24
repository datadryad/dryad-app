#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
Dir[File.join(__dir__, 'app', '*.rb')].each { |file| require file }
require 'active_support/core_ext/object/to_query'

Bundler.require(:default)

Config.initialize(environment: ENV['RAILS_ENV'] || 'development')

State.create_pid

byebug

Config.logger.info("Starting notifier run for #{Config.environment} environment")

State.ensure_statefile

# get records for each set and time range
State.sets.each do |set|
  # get errored notifications and try them again
  set.retry_list.each do |item|
    Config.logger.info("Retrying notification of dryad for doi:#{item[:doi]}, merritt_id: #{item[:merritt_id]}")
    dn = DryadNotifier.new(doi: item[:doi], merritt_id: item[:merritt_id])
    set.remove_retry_item(doi: item[:doi]) if dn.notify == true
  end

  # get new records from OAI
  records = DatasetRecord.find(start_time: set.last_retrieved, end_time: Time.new.utc, set: set.name)
  last_retrieved = set.last_retrieved  # default to old value for no records in set
  records.each do |record|
    next if record.deleted?
    Config.logger.info("Notifying Dryad of status for doi:#{record.doi} ---- #{record.title} (#{record.timestamp.iso8601})")
    last_retrieved = record.timestamp

    # send status updates to Dryad for merritt state and add any failed items to the retry list
    dn = DryadNotifier.new(doi: record.doi, merritt_id: record.merritt_id)
    set.add_retry_item(doi: record.doi, merritt_id: record.merritt_id) unless dn.notify
  end
  set.last_retrieved = last_retrieved
  # save the state to the file after each set has run
  State.save_sets_state
end

Config.logger.info("Finished notifier run for #{Config.environment} environment\n\n")

State.remove_pid
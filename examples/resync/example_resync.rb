#! /usr/bin/env ruby

require 'stash/harvester'

config = Stash::Harvester::Resync::ResyncSourceConfig.from_yaml(
  File.read('resync_source.yml')
)

# Alternatively:
#
# config = Stash::Harvester::Resync::ResyncSourceConfig.new(
#   capability_list_url: 'http://localhost:8888/capabilitylist.xml'
# )

task = Stash::Harvester::Resync::ResyncHarvestTask.new(
  config: config,
  from_time: Time.utc(2015, 7, 13, 22, 17),
  until_time: Time.now.utc
)

response = task.harvest_records
response.each do |record|
  puts "#{record.timestamp}\t#{record.identifier}"
end

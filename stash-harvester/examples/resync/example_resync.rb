#! /usr/bin/env ruby

require 'stash/harvester'

config = Stash::Harvester::SourceConfig.from_yaml(
  File.read('resync_source.yml')
)

# Alternatively:
#
# config = Stash::Harvester::Resync::ResyncSourceConfig.new(
#   capability_list_url: 'http://localhost:8888/capabilitylist.xml'
# )

task = config.create_harvest_task(
  from_time: Time.utc(2015, 7, 13, 22, 17),
  until_time: Time.now.utc
)

response = task.harvest_records
response.each do |record|
  puts "#{record.timestamp}\t#{record.identifier}"
end

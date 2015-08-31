#! /usr/bin/env ruby

require 'stash/harvester'

config = Stash::Harvester::OAI::OAISourceConfig.from_yaml(
  File.read('oai_source.yml')
)

puts config.to_h

# Alternatively:
#
# config = Stash::Harvester::OAI::OAISourceConfig.new(
#   oai_base_url: 'http://oai.datacite.org/oai',
#   metadata_prefix: 'oai_datacite',
#   set: 'REFQUALITY'
# )

task = Stash::Harvester::OAI::OAIHarvestTask.new(
  config: config,
  from_time: Time.utc(2013, 6, 1),
  until_time: Time.utc(2013, 6, 30)
)

response = task.harvest_records
response.each do |record|
  puts "#{record.timestamp}\t#{record.identifier}"
end

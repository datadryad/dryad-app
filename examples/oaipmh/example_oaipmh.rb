#! /usr/bin/env ruby

require 'stash/harvester'

config = Stash::Harvester::SourceConfig.from_yaml(
  File.read('oai_source.yml')
)

# Alternatively:
#
# config = Stash::Harvester::OAI::OAISourceConfig.new(
#   oai_base_url: 'http://oai.datacite.org/oai',
#   metadata_prefix: 'oai_datacite',
#   set: 'REFQUALITY'
# )

task = config.create_harvest_task(
  from_time: Time.utc(2013, 6, 1),
  until_time: Time.utc(2013, 6, 30)
)

response = task.harvest_records
response.each do |record|
  puts "#{record.timestamp}\t#{record.identifier}"
end

#! /usr/bin/env ruby

# Note: This assumes we're running from the root of the stash-harvester project
$LOAD_PATH << File.dirname(__FILE__)
require 'lib/stash/harvester'

config = Stash::Harvester::OAIPMH::OAISourceConfig.new(
  oai_base_url: 'http://oai.datacite.org/oai',
  metadata_prefix: 'oai_datacite',
  set: 'REFQUALITY'
)

task = Stash::Harvester::OAIPMH::OAIHarvestTask.new(
  config: config,
  from_time: Time.utc(2013, 6, 1),
  until_time: Time.utc(2013, 6, 30)
)

response = task.harvest_records
response.each do |record|
  puts "#{record.timestamp}\t#{record.identifier}"
end

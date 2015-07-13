#! /usr/bin/env ruby

# Note: This assumes we're running from the root of the stash-harvester project
$LOAD_PATH << File.dirname(__FILE__)
require 'lib/stash/harvester'

oai_base_url = 'http://oai.datacite.org/oai'
metadata_prefix = 'datacite'
from_time = Time.utc(2013, 6, 1)
until_time = Time.utc(2013, 6, 30)

list_records_config = Stash::Harvester::OAIPMH::OAIConfig.new(
  oai_base_url: oai_base_url,
  metadata_prefix: metadata_prefix,
  set: 'REFQUALITY'
)

list_records_task = Stash::Harvester::OAIPMH::ListRecordsTask.new(
  config: list_records_config,
  from_time: from_time,
  until_time: until_time
)

response = list_records_task.harvest_records
response.each do |record|
  puts record.identifier
end

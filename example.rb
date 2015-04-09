#! /usr/bin/env ruby

fail Exception, 'stash-harvester requires Ruby 2.2' unless RUBY_VERSION =~ /^2.2/

# Note: This assumes we're running from the root of the stash-harvester project
$LOAD_PATH << File.dirname(__FILE__)
require 'lib/stash/harvester'

oai_base_url = 'http://oai.datacite.org/oai'
from_time = Time.utc(2011, 6, 1)
until_time = Time.utc(2011, 6, 30)
metadata_prefix = 'datacite'

list_records_config = Stash::Harvester::ListRecordsConfig.new(
  from_time: from_time,
  until_time: until_time,
  metadata_prefix: metadata_prefix
)

list_records_task = Stash::Harvester::ListRecordsTask.new(
  oai_base_url: oai_base_url,
  config: list_records_config
)

response = list_records_task.list_records
response.each do |record|
  puts record.identifier
end

#! /usr/bin/env ruby

fail Exception, 'dash2-harvester requires Ruby 2.2' unless RUBY_VERSION =~ /^2.2/

# Note: This assumes we're running from the root of the dash2-harvester project
$LOAD_PATH << File.dirname(__FILE__)
require 'lib/dash2/harvester'

# oai_base_url = 'http://oai.datacite.org/oai'
# from_time = Time.utc(2011, 6, 1)
# until_time = Time.utc(2011, 6, 30)
# metadata_prefix = 'datacite'

oai_base_url = 'http://www.pubmedcentral.gov/oai/oai.cgi'
from_time = Time.utc(2002, 3, 1)
until_time = Time.utc(2003, 7, 31)
metadata_prefix = 'oai_dc'

list_records_config = Dash2::Harvester::ListRecordsConfig.new(
  from_time: from_time,
  until_time: until_time,
  metadata_prefix: metadata_prefix
)

list_records_task = Dash2::Harvester::ListRecordsTask.new(
  oai_base_url: oai_base_url,
  config: list_records_config
)

response = list_records_task.list_records
response.each do |record|
  puts record.metadata_root
end

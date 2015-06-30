#! /usr/bin/env ruby

# Note: This assumes we're running from the root of the stash-harvester project
$LOAD_PATH << File.dirname(__FILE__)
require 'lib/stash/harvester'

oai_base_url = 'http://oai.datacite.org/oai'
from_time = Time.utc(2014, 6, 29)
until_time = Time.utc(2015, 6, 30)
metadata_prefix = 'oai_datacite'

list_records_config = Stash::Harvester::OAIPMH::ListRecordsConfig.new(
  from_time: from_time,
  until_time: until_time,
  metadata_prefix: metadata_prefix
)

list_records_task = Stash::Harvester::OAIPMH::ListRecordsTask.new(
  oai_base_url: oai_base_url,
  config: list_records_config
)

response = list_records_task.list_records

formatter = REXML::Formatters::Pretty.new
formatter.compact = true
formatter.width = 80

found_count, total_count, max = 0, 0, (1000 - 74)
counts_by_version = {}

require 'set'
found_identifiers = Set.new

begin
  response.each do |record|
    total_count += 1
    print '.' if total_count % 10 == 0
    unless record.deleted?
      root = record.metadata_root
      schema_version = REXML::XPath.first(root, '//*[local-name()="schemaVersion"]').text
      counts_by_version[schema_version] ||= 0
      counts_by_version[schema_version] = counts_by_version[schema_version] + 1
      if schema_version.to_f >= 3
        resource = REXML::XPath.first(root, '//*[local-name()="resource"]')
        identifier = REXML::XPath.first(resource, '//*[local-name()="identifier"]/text()')
        if found_identifiers.add?(identifier)
          print('!')
          outfile = "/tmp/datacite/#{record.identifier.gsub(':', '-')}.xml"
          File.open(outfile, 'w') do |f|
            f.puts('<?xml version="1.0" encoding="UTF-8"?>')
            formatter.write(resource, f)
            f.puts
          end
          found_count += 1
        end
      end
    end
    break if found_count > max
  end
ensure
  puts "\n#{counts_by_version}"
end

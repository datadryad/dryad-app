#! /usr/bin/env ruby

raise Exception, 'dash2-harvester requires Ruby 2.2' unless RUBY_VERSION =~ /^2.2/

# Note: This assumes we're running from the root of the dash2-harvester project
$LOAD_PATH << File.dirname(__FILE__)
require 'lib/dash2/harvester'

from_time = Time.new(2011, 6, 1)
until_time = Time.new(2011, 6, 30)
metadata_prefix = 'datacite'

harvest_task = Dash2::Harvester::HarvestTask.new(
    oai_base_url: 'http://oai.datacite.org/oai',
    from_time: from_time,
    until_time: until_time,
    metadata_prefix: metadata_prefix
)

response = harvest_task.harvest
response.each do |record|
  puts record.metadata_root
end

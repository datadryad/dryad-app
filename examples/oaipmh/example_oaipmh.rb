#! /usr/bin/env ruby

require 'stash/harvester'

config = Stash::Harvester::SourceConfig.from_file('oai_source.yml', :source)

# Alternatively:
#
# config = Stash::Harvester::OAI::OAISourceConfig.new(
#   oai_base_url: 'http://uc3-mrtoai-dev.cdlib.org:37001/mrtoai/oai/v2',
#   metadata_prefix: 'stash_wrapper',
#   set: 'dash_cdl',
#   seconds_granularity: true
# )

task = config.create_harvest_task(
  from_time: Date.new(2015, 9, 30),
  until_time: Date.new(2015, 10, 31)
)

response = task.harvest_records
response.each do |record|
  puts "#{record.timestamp}\t#{record.identifier}"
end

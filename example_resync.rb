#! /usr/bin/env ruby

# Note: This assumes we're running from the root of the stash-harvester project
$LOAD_PATH << File.dirname(__FILE__)
require 'lib/stash/harvester'

capability_list_uri = 'http://localhost:8888/capabilitylist.xml'
from_time = Time.utc(2015, 6, 24, 23, 20)
until_time = Time.utc(2015, 6, 24, 23, 29, 59)

sync_task = Stash::Harvester::Resync::SyncTask.new(
  capability_list_uri: capability_list_uri,
  from_time: from_time,
  until_time: until_time
)

response = sync_task.download
response.each do |resource_content|
  puts resource_content.uri
end

puts response.size

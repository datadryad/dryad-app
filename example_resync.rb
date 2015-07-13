#! /usr/bin/env ruby

# Note: This assumes we're running from the root of the stash-harvester project
$LOAD_PATH << File.dirname(__FILE__)
require 'lib/stash/harvester'

# URL from resync-simulator (https://github.com/resync/resync-simulator);
# timestamps should reflect when the simulator was started
capability_list_uri = 'http://localhost:8888/capabilitylist.xml'
from_time = Time.utc(2015, 7, 13, 22, 17)
until_time = Time.utc(2015, 7, 13, 22, 18)

sync_task = Stash::Harvester::Resync::SyncTask.new(
  capability_list_uri: capability_list_uri,
  from_time: from_time,
  until_time: until_time
)

response = sync_task.harvest_records
response.each do |resource_content|
  puts "#{resource_content.timestamp}\t#{resource_content.identifier}"
end

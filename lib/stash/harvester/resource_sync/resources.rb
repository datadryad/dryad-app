require 'resync/client'

module Stash
  module Harvester
    module Resync
      class Resources

        def initialize(capability_list_uri:)
          @capability_list_uri = capability_list_uri
        end

        def harvest(client: Client.new, from_time: nil, until_time: nil)
          capability_list = fetch_capability_list(client)
          task = if from_time || until_time
                   HarvestResourcesTask.new(capability_list)
                 else
                   HarvestChangesTask(capability_list: capability_list, from_time: from_time, until_time: until_time)
                 end
        end

        def fetch_capability_list(client)
          capability_list = client.get_and_parse(@capability_list_uri)
          fail "Resource at #{@capability_list_uri} is not a capability list" unless capability_list.respond_to?(:resource_for)
          capability_list
        end

      end

      class HarvestResourcesTask
        def initialize(capability_list)
          @root_list = capability_list.resource_for('resourcedump') || capability_list.resource_for('resourcelist')
        end
      end

      class HarvestChangesTask
        def initialize(capability_list:, from_time: nil, until_time: nil)
          @time_range = (from_time || Time.utc(0))..(until_time || Time.new.utc)
          @root_list = capability_list.resource_for('changedump') || capability_list.resource_for('changelist')
        end
      end

    end
  end
end

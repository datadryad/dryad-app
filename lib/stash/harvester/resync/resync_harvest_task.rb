require 'resync/client'

module Stash
  module Harvester
    module Resync

      # Class representing a single ResourceSync harvest operation.
      # If a time range (open or closed) is provided, the task will
      # harvest changes in that time range; otherwise, it will harvest
      # all resources. [ChangeDumps](http://www.rubydoc.info/gems/resync/0.1.2/Resync/ChangeDump)
      # and [ResourceDumps](http://www.rubydoc.info/gems/resync/0.1.2/Resync/ResourceDump)
      # are preferred to [ChangeLists](http://www.rubydoc.info/gems/resync/0.1.2/Resync/ChangeList)
      # and [ResourceLists](http://www.rubydoc.info/gems/resync/0.1.2/Resync/ResourceList),
      # [ChangeListIndices](http://www.rubydoc.info/gems/resync/0.1.2/Resync/ChangeListIndex)
      # etc. will be transparently crawled to reach the nested lists.
      class ResyncHarvestTask < HarvestTask

        # Added to the current time to create an end timestamp for open ranges
        JULIAN_YEAR_SECONDS = 365.25 * 86_400

        # Creates a new `IncrementalSyncTask` for synchronizing with the set of
        # resources whose capabilities are enumerated by the specified capability
        # list
        # @param config [ResyncSourceConfig] the source configuration. *(Required)*
        # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
        #   If `from_time` is omitted, harvesting will extend back to the earliest datestamp in the
        #   repository. (Optional)
        # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
        #   If `until_time` is omitted, harvesting will extend forward to the latest datestamp in the
        #   repository. (Optional)
        def initialize(config:, from_time: nil, until_time: nil)
          super
        end

        # Harvests the records from the ResourceSync source.
        # @return [Enumerator::Lazy<ResyncRecord>
        def harvest_records
          resources = time_range ? all_changes : all_resources
          resources.map { |r| ResyncRecord.new(r) }
        end

        # Returns the URI of the initial capability list retrieved by this harvest.
        #
        # @return [URI] the capability list URI
        def query_uri
          config.source_uri
        end

        private

        def client
          @client ||= ::Resync::Client.new
        end

        def capability_list
          capability_list_uri = query_uri
          @capability_list ||= client.get_and_parse(capability_list_uri)
        end

        def time_range
          @time_range ||= (from_time || until_time) ? range_start..range_end : nil
        end

        def packaged_changes(change_dump, time_range)
          return nil unless change_dump
          zip_packages = change_dump.all_zip_packages(in_range: time_range)
          zip_packages.flat_map(&:bitstreams).map(&:resource)
        end

        def packaged_resources(resource_dump)
          return nil unless resource_dump
          zip_packages = resource_dump.all_zip_packages
          zip_packages.flat_map(&:bitstreams).map(&:resource)
        end

        def all_resources
          packaged_resources(capability_list.resource_dump) || capability_list.resource_list.all_resources
        end

        def all_changes
          # TODO: filter by time_range, most recent for each URI
          packaged_changes(capability_list.change_dump, time_range) || capability_list.change_list.all_changes(in_range: time_range)
        end

        def range_start
          from_time || Time.utc(0)
        end

        def range_end
          until_time || (Time.new.utc + JULIAN_YEAR_SECONDS)
        end

      end
    end
  end
end

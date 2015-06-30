require 'resync/client'

module Stash
  module Harvester
    module Resync
      class SyncTask

        # ------------------------------------------------------------
        # Constants

        # Added to the current time to create an end
        JULIAN_YEAR_SECONDS = 365.25 * 86_400

        # ------------------------------------------------------------
        # Attributes

        attr_reader :capability_list_uri
        attr_reader :from_time
        attr_reader :until_time

        # ------------------------------------------------------------
        # Initializer
        # Creates a new +IncrementalSyncTask+ for synchronizing with the set of
        # resources whose capabilities are enumerated by the specified capability
        # list
        # @param capability_list_uri [URI, String] the base URL of the repository. *(Required)*
        # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
        #   If +from_time+ is omitted, harvesting will extend back to the earliest datestamp in the
        #   repository. (Optional)
        # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
        #   If +until_time+ is omitted, harvesting will extend forward to the latest datestamp in the
        #   repository. (Optional)
        def initialize(capability_list_uri:, from_time: nil, until_time: nil)
          @capability_list_uri = to_uri(capability_list_uri)
          @from_time, @until_time = valid_range(from_time, until_time)
        end

        # ------------------------------------------------------------
        # Methods

        def download
          all_resources.map { |r| ResourceContent.new(r) }
        end

        # ------------------------------------------------------------
        # Custom accessors

        def client
          @client ||= ::Resync::Client.new
        end

        def capability_list
          @capability_list ||= client.get_and_parse(capability_list_uri)
        end

        def time_range
          @time_range ||= (from_time || until_time) ? range_start..range_end : nil
        end

        # ------------------------------------------------------------
        # Private methods

        private

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
          if time_range
            # TODO: filter by time_range, most recent for each URI
            packaged_changes(capability_list.change_dump, time_range) || capability_list.change_list.all_changes(in_range: time_range)
          else
            packaged_resources(capability_list.resource_dump) || capability_list.resource_list.all_resources
          end
        end

        # ------------------------------
        # Parameter validators

        def utc_or_nil(time)
          if time && !time.utc?
            fail ArgumentError, "time #{time}| must be in UTC"
          else
            time
          end
        end

        def valid_range(from_time, until_time)
          if from_time && until_time && from_time.to_i > until_time.to_i
            fail RangeError, "from_time #{from_time} must be <= until_time #{until_time}"
          else
            [utc_or_nil(from_time), utc_or_nil(until_time)]
          end
        end

        # ------------------------------
        # Conversions

        def range_start
          from_time || Time.utc(0)
        end

        def range_end
          until_time || (Time.new.utc + JULIAN_YEAR_SECONDS)
        end

        def to_uri(url)
          (url.is_a? URI) ? url : URI.parse(url)
        end

      end
    end
  end
end

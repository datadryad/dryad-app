require_relative '../source_config'

module Stash
  module Harvester
    module Resync

      # The configuration of a ResourceSync data source.
      class ResyncSourceConfig < SourceConfig

        # Constructs a new {ResyncSourceConfig} for resources described by
        # the specified Capability List.
        #
        # @param capability_list_url [URI, String] the URL of the capability list.
        #   *(Required)*
        # @raise [URI::InvalidURIError] if +capability_list_url+ is a string that is not a valid URI
        def initialize(capability_list_url:)
          super(source_url: capability_list_url)
        end

      end
    end
  end
end

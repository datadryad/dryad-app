require 'resync/client'
require 'stash/harvester/harvested_record'

module Stash
  module Harvester
    module Resync

      # A utility wrapper around `Resync::Resource` that includes both the resource
      # and the content of the resource
      #
      # @!attribute [r] timestamp
      #   @return [Time] The modification time of the resource.
      # @!attribute [r] deleted
      #   @return [Boolean] True if this change indicates a deletion, false otherwise.
      # @!attribute [r] identifier
      #   @return [String] The URI of the record.
      # @!attribute [r] metadata_root
      #   @return [REXML::Element] The root (inner) element of the record metadata.
      class ResyncRecord < Stash::Harvester::HarvestedRecord

        # Creates a new {ResyncRecord} wrapping the specified resource. The resource
        # is responsible for providing its own content; any resource provided by a
        # [Resync::Client](http://www.rubydoc.info/github/dmolesUC3/resync-client/Resync/Client) should be able to do this.
        #
        # @param resource [Resync::Resource with Resync::Client::Mixins::Downloadable, Resync::Client::Mixins::BitstreamResource]
        #   the resource
        def initialize(resource)
          super(
            identifier: resource.uri.to_s,
            timestamp: resource.modified_time,
            deleted: begin
              metadata = resource.metadata
              metadata && metadata.change == ::Resync::Types::Change::DELETED
            end
          )
          @resource = resource
        end

        # The content of the resource, as retrieved from the resource URL, or from
        # the containing ZIP bitstream package if one is available
        #
        # @return [String] the content of the resource
        def content
          @content ||= @deleted ? nil : content_from(@resource)
        end

        private

        def content_from(resource)
          if resource.respond_to?(:bitstream)
            bitstream = resource.bitstream
            bitstream.content
          elsif resource.respond_to?(:get)
            resource.get
          end
        end
      end
    end
  end
end

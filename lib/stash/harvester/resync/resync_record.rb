require 'lazy'
require 'resync/client'
require_relative '../harvested_record'

module Stash
  module Harvester
    module Resync

      # A utility wrapper around +Resync::Resource+ that includes both the resource
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

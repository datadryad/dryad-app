require 'lazy'
require 'resync/client'

module Stash
  module Harvester
    module Resync

      # A utility wrapper around +Resync::Resource+ that includes both the resource
      # and the content of the resource
      class ResourceContent

        attr_reader :modified_time
        attr_reader :uri
        attr_reader :content
        attr_reader :deleted

        alias_method :deleted?, :deleted

        def initialize(resource)
          @modified_time = resource.modified_time
          @uri = resource.uri
          metadata = resource.metadata
          @deleted = metadata && metadata.change == ::Resync::Types::Change::DELETED
          @content = Lazy.promise { @deleted ? nil : content_from(resource) }
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

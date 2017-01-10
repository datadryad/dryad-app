require 'stash_engine'
require 'stash_datacite'

module Stash
  module Merritt
    class Package
      attr_reader :resource_id

      def initialize(resource_id)
        @resource_id = resource_id
      end

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      def datacite_xml
        # TODO
      end

      def datacite_xml_str
        # TODO
      end

      def stash_wrapper_xml
        # TODO
      end

      def oai_dc_xml
        # TODO
      end

      def dataone_manifest_txt
        # TODO
      end

      def mrt_delete_txt
        # TODO
      end

      def archive_zip
        # TODO
      end

      def cleanup
        # TODO
      end
    end
  end
end

module Stash
  module Repo
    class MerrittDeleteBuilder < FileBuilder
      attr_reader :resource_id

      def initialize(resource_id:)
        super(file_name: 'mrt-delete.txt')
        @resource_id = resource_id
      end

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      def mime_type
        MIME::Types['text/plain'].first
      end

      def contents
        del_files = resource.data_files.deleted
        del_files.blank? ? nil : del_files.map(&:download_filename).join("\n")
      end
    end
  end
end

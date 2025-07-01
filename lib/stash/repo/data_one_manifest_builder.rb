require 'ostruct'

module Stash
  module Repo
    class DataOneManifestBuilder < FileBuilder
      attr_reader :uploads

      # @param uploads [Array[StashEngine::DataFile]] a list of file uploads
      def initialize(uploads)
        super(file_name: 'mrt-dataone-manifest.txt')
        @uploads = uploads
      end

      def mime_type
        MIME::Types['text/plain'].first
      end

      def contents
        files = uploads.map do |upload|
          OpenStruct.new(file_name: upload.download_filename, mime_type: upload.upload_content_type)
        end
        # manifest = ::Merritt::Manifest::DataONE.new(files: files)
        # manifest.write_to_string
        "This manifest is no longer used, but it would be used for #{files}"
      end
    end
  end
end

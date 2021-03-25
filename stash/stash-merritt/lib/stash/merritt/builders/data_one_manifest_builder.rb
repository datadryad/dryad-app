require 'ostruct'
require 'stash/repo/file_builder'
require 'merritt'

module Stash
  module Merritt
    module Builders
      class DataONEManifestBuilder < Stash::Repo::FileBuilder
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
            OpenStruct.new(file_name: upload.upload_file_name, mime_type: upload.upload_content_type)
          end
          manifest = ::Merritt::Manifest::DataONE.new(files: files)
          manifest.write_to_string
        end
      end
    end
  end
end

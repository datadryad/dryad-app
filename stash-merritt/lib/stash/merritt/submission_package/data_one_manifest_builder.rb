require 'stash/repo/file_builder'

module Stash
  module Merritt
    class SubmissionPackage
      class DataONEManifestBuilder < Stash::Repo::FileBuilder
        HEADER = [
          '#%dataonem_0.1',
          '#%profile | http://uc3.cdlib.org/registry/ingest/manifest/mrt-dataone-manifest',
          '#%prefix | dom: | http://uc3.cdlib.org/ontology/dataonem',
          '#%prefix | mrt: | http://uc3.cdlib.org/ontology/mom',
          '#%fields | dom:scienceMetadataFile | dom:scienceMetadataFormat | dom:scienceDataFile | mrt:mimeType'
        ].join("\n").freeze

        METADATA_FILES = {
          'mrt-datacite.xml' => 'http://datacite.org/schema/kernel-3.1',
          'mrt-oaidc.xml' => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd'
        }.freeze

        attr_reader :uploads

        # @param uploads [Array[StashEngine::FileUpload]] a list of file uploads
        def initialize(uploads)
          super(file_name: 'mrt-dataone-manifest.txt')
          @uploads = uploads
        end

        def contents
          content = [HEADER]
          uploads.each do |upload|
            METADATA_FILES.each do |md_filename, md_schema|
              content << "#{md_filename} | #{md_schema} | #{upload.upload_file_name} | #{upload.upload_content_type}"
            end
          end
          content << "#%eof\n"
          content.join("\n")
        end
      end
    end
  end
end

require 'stash/repo/util/file_builder'

# TODO: remove from stash_datacite
module Stash::Merritt::Package
  class DataONEManifestBuilder < Stash::Repo::Util::FileBuilder
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

    attr_reader :files

    # @param files [Array[Hash]] a list of "files", where each file is a hash
    #   keyed by `:name` and `:type`
    def initialize(files)
      @files = files
    end

    def file_name
      'mrt-dataone-manifest.txt'
    end

    def contents
      content = [HEADER]
      # TODO: do we really need to expect nils in the file list?
      files.compact.each do |file|
        METADATA_FILES.each do |md_filename, md_schema|
          content << "#{md_filename} | #{md_schema} | #{file[:name]} | #{file[:type]}"
        end
      end
      content << "#%eof\n"
      content.join("\n")
    end
  end
end

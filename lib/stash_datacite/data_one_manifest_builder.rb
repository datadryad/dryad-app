module StashDatacite
  module Resource
    class DataONEManifestBuilder
      HEADER = [
        '#%dataonem_0.1 ',
        '#%profile | http://uc3.cdlib.org/registry/ingest/manifest/mrt-dataone-manifest ',
        '#%prefix | dom: | http://uc3.cdlib.org/ontology/dataonem ',
        '#%prefix | mrt: | http://uc3.cdlib.org/ontology/mom ',
        '#%fields | dom:scienceMetadataFile | dom:scienceMetadataFormat | dom:scienceDataFile | mrt:mimeType ',
      ].join("\n").freeze

      METADATA_FILES = {
        'mrt-datacite.xml' => 'http://datacite.org/schema/kernel-3.1',
        'mrt-oaidc.xml' => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd'
      }.freeze

      attr_reader :files

      def initialize(files)
        @files = files
      end

      def build_dataone_manifest
        content = [HEADER]
        # TODO: do we really need to expect nils in the file list?
        files.compact.each do |file|
          METADATA_FILES.each do |md_filename, md_schema|
            content << "#{md_filename} | #{md_schema} | #{file[:name]} | #{file[:type]}"
          end
        end
        content << '#%eof'
        content.join("\n")
      end

    end
  end
end

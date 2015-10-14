module Stash
  module Harvester
    class MetadataConfig < ConfigBase
      CONFIG_KEY = :mapping

      # TODO: Should this assume it's always already extracted from the wrapper?
      def to_solr_hash(_metadata_xml)
        fail NoMethodError, "#{self.class} should override #to_solr_hash to map from metadata XML to Solr fields, but it doesn't"
      end

    end
  end
end

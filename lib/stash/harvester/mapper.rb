module Stash
  module Harvester
    class Mapper < ConfigBase
      CONFIG_KEY = :mapping

      def to_solr_hash(metadata_xml)
        fail NoMethodError, "#{self.class} should override #to_solr_hash to map from metadata XML to Solr fields, but it doesn't"
      end

    end
  end
end

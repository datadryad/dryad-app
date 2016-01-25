module Stash
  module Indexer
    # Support for indexing Datacite into the Geoblacklight Solr schema
    module DataciteGeoblacklight
      Dir.glob(File.expand_path('../datacite_geoblacklight/*.rb', __FILE__), &method(:require))
    end
  end
end

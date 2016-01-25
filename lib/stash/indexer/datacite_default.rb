module Stash
  module Indexer
    # Support for indexing Datacite into the Stash default Solr schema
    module DataciteDefault
      Dir.glob(File.expand_path('../datacite_default/*.rb', __FILE__), &method(:require))
    end
  end
end

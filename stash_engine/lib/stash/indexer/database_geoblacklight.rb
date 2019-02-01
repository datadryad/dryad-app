module Stash
  module Indexer
    # Support for indexing Datacite into the Geoblacklight Solr schema
    module DataciteGeoblacklight
      Dir.glob(File.expand_path('database_geoblacklight/*.rb', __dir__)).sort.each(&method(:require))
    end
  end
end

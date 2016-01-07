require 'uri'
require 'oai/client'

module Stash
  module Harvester
    # Indexing support for [Apache Solr](http://lucene.apache.org/solr/)
    module Solr
      Dir.glob(File.expand_path('../datacite_default/*.rb', __FILE__), &method(:require))
    end
  end
end

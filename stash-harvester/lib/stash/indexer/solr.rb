require 'uri'
require 'oai/client'

module Stash
  module Harvester
    # Indexing support for [Apache Solr](http://lucene.apache.org/solr/)
    module Solr
      Dir.glob(File.expand_path('solr/*.rb', __dir__)).sort.each(&method(:require))
    end
  end
end

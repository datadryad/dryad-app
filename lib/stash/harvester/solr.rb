require 'uri'
require 'oai/client'

module Stash
  module Harvester
    # Indexing support for {http://lucene.apache.org/solr/ Apache Solr}
    module Solr
      Dir.glob(File.expand_path('../solr/*.rb', __FILE__), &method(:require))
    end
  end
end

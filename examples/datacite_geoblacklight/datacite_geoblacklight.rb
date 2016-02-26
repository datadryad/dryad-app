#! /usr/bin/env ruby

require 'stash/wrapper'
require 'stash/indexer/datacite_geoblacklight'

include Stash::Wrapper

datacite_xml = REXML::Document.new(File.read('datacite-example-full-v3.1.xml')).root
wrapper = StashWrapper.new(
  identifier: Identifier.new(type: IdentifierType::DOI, value: '10.5072/example-full'),
  version: Version.new(number: 4, date: Date.new(2014, 10, 17), note: 'Full DataCite 3.1 XML Example accessed 2014-01-06'),
  license: License.new(
    name: 'CC0 1.0 Universal',
    uri: URI('http://creativecommons.org/publicdomain/zero/1.0/')
  ),
  embargo: Embargo.new(type: EmbargoType::DOWNLOAD, period: '1 year', start_date: Date.new(2014, 10, 17), end_date: Date.new(2015, 10, 17)),
  inventory: Inventory.new(files: [StashFile.new(pathname: 'datacite-example-full-v3.1.xml', size_bytes: 3072, mime_type: 'application/xml')]),
  descriptive_elements: [datacite_xml]
)

# index_config = SolrIndexConfig(url: 'http://192.168.99.100:32768/')
# indexer = index_config.create_indexer

mapper = Stash::Indexer::DataciteGeoblacklight::Mapper.new
index_document = mapper.to_index_document(wrapper)

require 'rsolr'
solr = RSolr.connect(url: 'http://192.168.99.100:32768/solr/geoblacklight')
# solr = RSolr.connect(url: 'http://uc3-dash2solr-dev.cdlib.org:8983/solr/geoblacklight')
solr.add index_document # TODO: Indexer should configure batch size

solr.commit



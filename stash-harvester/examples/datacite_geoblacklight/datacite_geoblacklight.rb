#! /usr/bin/env ruby

require 'stash/harvester'
require 'stash/indexer'
require 'stash/wrapper'

class FileRecord < Stash::Harvester::HarvestedRecord
  def initialize(filename)
    @source_xml = File.read(filename)
    @wrapper = Stash::Wrapper::StashWrapper.parse_xml(@source_xml)
    super(identifier: @wrapper.id_value, timestamp: File.mtime(filename).utc)
  end

  def content
    @source_xml
  end
end

records = %w[
  wrapped-datacite-all-geodata.xml
  wrapped-datacite-no-geodata.xml
  wrapped-datacite-place-only.xml
].map { |source| FileRecord.new(source) }

mapper = Stash::Indexer::DataciteGeoblacklight::Mapper.new
records.each do |r|
  require 'pp'
  pp mapper.to_index_document(r.as_wrapper)
end

index_config = Stash::Indexer::Solr::SolrIndexConfig.new(url: 'http://uc3-dash2solr-dev.cdlib.org:8983/solr/geoblacklight')
# index_config = Stash::Indexer::Solr::SolrIndexConfig.new(url: 'http://192.168.99.100:32768/')
indexer = index_config.create_indexer(mapper)
indexer.index(records) do |result|
  if result.success?
    puts "Indexed #{result.record_id} at #{result.timestamp}"
  else
    puts "Indexing #{result.record_id} at #{result.timestamp} failed"
    result.errors.each do |e|
      STDERR.puts(e.backtrace)
    end
  end
end

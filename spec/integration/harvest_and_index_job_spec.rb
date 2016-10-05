require 'spec_helper'

module Stash
  describe HarvestAndIndexJob do
    attr_reader :job
    attr_reader :indexed

    def oai_doc
      REXML::Document.new(@oai_feed)
    end

    before(:each) do
      oai_client = instance_double(OAI::Client)
      allow(oai_client).to receive(:list_records) {
        OAI::ListRecordsResponse.new(oai_doc) {} # empty resumption block
      }
      allow(oai_client).to receive(:build_uri).and_return('http://oaipmh.example.org/ListRecords')
      allow(OAI::Client).to receive(:new).and_return(oai_client)

      @indexed = []

      rsolr = instance_double(RSolr::Client)
      allow(rsolr).to receive(:add) { |doc| @indexed << doc }
      allow(rsolr).to receive(:commit)
      allow(RSolr).to receive(:connect).and_return(rsolr)

      @job = HarvestAndIndexJob.new(
        source_config: Harvester::OAI::OAISourceConfig.new(oai_base_url: 'http://oaipmh.example.org/'),
        index_config: Indexer::Solr::SolrIndexConfig.new(url: 'http://solr.example.org/'),
        metadata_mapper: Indexer::DataciteGeoblacklight::Mapper.new,
        persistence_manager: Stash::NoOpPersistenceManager.new
      )
    end

    it 'harvests and indexes a minimal example' do
      @oai_feed = File.read('spec/data/oai/merritt-example-minimal.xml').freeze
      results = []
      job.harvest_and_index do |result|
        results << result
      end
      expect(results.size).to eq(2)
      expect(indexed.size).to eq(2)
    end

    it 'harvests and indexes a maximal example' do
      @oai_feed = File.read('spec/data/oai/merritt-example.xml').freeze
      results = []
      job.harvest_and_index do |result|
        results << result
      end
      expect(indexed.size).to eq(537)
    end

  end
end

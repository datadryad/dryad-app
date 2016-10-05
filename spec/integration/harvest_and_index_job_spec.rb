require 'spec_helper'

module Stash
  describe HarvestAndIndexJob do
    attr_reader :oai_feed

    attr_reader :job
    attr_reader :indexed

    before(:all) do
      @oai_feed = File.read('spec/data/oai/merritt-example.xml').freeze
    end

    before(:each) do
      oai_doc = REXML::Document.new(oai_feed)
      oai_response = OAI::ListRecordsResponse.new(oai_doc)
      oai_client = instance_double(OAI::Client)
      allow(oai_client).to receive(:list_records).and_return(oai_response)
      allow(oai_client).to receive(:build_uri).and_return('http://oaipmh.example.org/ListRecords')
      allow(OAI::Client).to receive(:new).and_return(oai_client)

      @indexed = []

      rsolr = instance_double(RSolr::Client)
      allow(rsolr).to receive(:add) { |doc| indexed << doc }
      allow(rsolr).to receive(:commit)
      allow(RSolr).to receive(:connect).and_return(rsolr)

      @job = HarvestAndIndexJob.new(
         source_config: Harvester::OAI::OAISourceConfig.new(oai_base_url: 'http://oaipmh.example.org/'),
         index_config: Indexer::Solr::SolrIndexConfig.new(url: 'http://solr.example.org/'),
         metadata_mapper: Indexer::DataciteGeoblacklight::Mapper.new,
         persistence_manager: Stash::NoOpPersistenceManager.new
      )
    end

    it 'harvests and indexes' do
      job.harvest_and_index
      expected(indexed.size).to eq(537)
    end

  end
end

require 'db_spec_helper'
require 'config/factory'

module Stash
  module HarvesterApp
    describe Application do
      describe 'start' do

        before(:each) do
          @config = Harvester::Config.from_file('spec/data/stash-harvester.yml')
          connection_info = @config.connection_info
          source_config = instance_double(Harvester::OAI::OAISourceConfig)


          source_uri = URI('http://oai.example.org/oai')
          index_uri = URI('http://solr.example.org/')

          harvest_task = instance_double(Harvester::HarvestTask)
          allow(source_config).to receive(:create_harvest_task) { harvest_task }
          allow(source_config).to receive(:source_uri) { source_uri }

          metadata_mapper = instance_double(Indexer::MetadataMapper)
          allow(metadata_mapper).to receive(:desc_from) { 'foo' }
          allow(metadata_mapper).to receive(:desc_to) { 'bar' }

          indexer = instance_double(Indexer::Indexer)
          index_config = instance_double(Indexer::IndexConfig)
          allow(index_config).to receive(:create_indexer).with(metadata_mapper) { indexer }
          allow(index_config).to receive(:uri) { index_uri }

          @config = Config.allocate
          allow(@config).to receive(:connection_info) { connection_info }
          allow(@config).to receive(:source_config) { source_config }
          allow(@config).to receive(:index_config) { index_config }
          allow(@config).to receive(:metadata_mapper) { metadata_mapper }

          records = Array.new(3) do |i|
            HarvestedRecord.new(identifier: "10.123/#{i}", timestamp: Time.utc(2015, 1, i + 1))
          end
          allow(harvest_task).to receive(:harvest_records) { records }
          expectation = allow(indexer).to receive(:index).and_return(records)
          records.each do |r|
            result = Indexer::IndexResult.new(record: r, timestamp: Time.now.utc)
            expectation.and_yield result
          end

        end

        it 'creates a harvest job' do
          from_time = Time.utc(2014, 1, 1)
          until_time = Time.utc(2016, 1, 1)

          from_str = '2014-01-01'
          until_str = '2016-01-01'

          now = Time.now
          app = Application.with_config(@config)
          app.start(from_time: from_time, until_time: until_time)

          job = Harvester::Models::HarvestJob.take
          expect(job.from_time).to eq(from_time)
          expect(job.until_time).to eq(until_time)
          expect(job.query_url).to eq("http://oai.example.org/oai?verb=ListRecords&from=#{from_str}&until=#{until_str}")
          expect(job.start_time.to_i).to be_within(1).of(now.to_i)
          expect(job.end_time.to_i).to be_within(1).of(now.to_i)
          expect(job.status).to be(Stash::Harvester::Models::Status::COMPLETED)
        end

        it 'creates an index job'

        it 'creates a harvested_record for each harvested record'

        it 'creates an indexed_record for each indexed record'

        it 'logs overall job failures'

        it 'sets the harvest status to failed in event of a pre-indexing failure'

        it 'sets the index status to failed in event of an indexing failure'
      end
    end
  end
end

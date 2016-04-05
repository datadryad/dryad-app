require 'spec_helper'
require 'stash/harvest_and_index_job'

module Stash
  describe HarvestAndIndexJob do

    before(:each) do
      @persistence_mgr = instance_double(PersistenceManager).as_null_object
    end

    describe '#initialize' do
      it 'creates a harvest task' do
        source_config = instance_double(Harvester::SourceConfig)
        from_time = Time.utc(1914, 8, 4, 23)
        until_time = Time.utc(1918, 11, 11, 10)
        harvest_task = instance_double(Harvester::HarvestTask)
        expect(source_config).to receive(:create_harvest_task).with(from_time: from_time, until_time: until_time) { harvest_task }

        index_config = instance_double(Indexer::IndexConfig)
        allow(index_config).to receive(:create_indexer)
        allow(index_config).to receive(:uri) { URI('http://solr.example.org/') }

        metadata_mapper = instance_double(Indexer::MetadataMapper)

        job = HarvestAndIndexJob.new(
          source_config: source_config,
          index_config: index_config,
          metadata_mapper: metadata_mapper,
          persistence_manager: @persistence_mgr,
          from_time: from_time,
          until_time: until_time
        )
        expect(job.harvest_task).to equal(harvest_task)
      end

      it 'creates an indexer' do
        source_config = instance_double(Harvester::SourceConfig)
        allow(source_config).to receive(:create_harvest_task)

        indexer = instance_double(Indexer::Indexer)

        index_config = instance_double(Indexer::IndexConfig)
        expect(index_config).to receive(:create_indexer) { indexer }
        allow(index_config).to receive(:uri) { URI('http://solr.example.org/') }

        metadata_mapper = instance_double(Indexer::MetadataMapper)

        job = HarvestAndIndexJob.new(source_config: source_config, index_config: index_config, metadata_mapper: metadata_mapper, persistence_manager: @persistence_mgr)
        expect(job.indexer).to equal(indexer)
      end
    end

    describe '#harvest_and_index' do

      before(:each) do
        @source_config = instance_double(Harvester::SourceConfig)
        @harvest_task = instance_double(Harvester::HarvestTask)
        allow(@source_config).to receive(:create_harvest_task) { @harvest_task }

        @metadata_mapper = instance_double(Indexer::MetadataMapper)

        @indexer = instance_double(Indexer::Indexer)
        @index_config = instance_double(Indexer::IndexConfig)
        allow(@index_config).to receive(:uri) { URI('http://solr.example.org/') }
        expect(@index_config).to receive(:create_indexer).with(@metadata_mapper) { @indexer }

        @records = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }.lazy
        allow(@harvest_task).to receive(:harvest_records) { @records }

        allow(@harvest_task).to receive(:from_time)
        allow(@harvest_task).to receive(:until_time)
        allow(@harvest_task).to receive(:query_uri) { URI('http://source.example.org/') }
      end

      it 'harvests and indexes records (even if no block given)' do
        expect(@indexer).to receive(:index).with(@records)
        job = HarvestAndIndexJob.new(source_config: @source_config, index_config: @index_config, metadata_mapper: @metadata_mapper, persistence_manager: @persistence_mgr)
        job.harvest_and_index
      end

      it 'yields the submission time and status (completed/failed) for each record' do
        expected_results = @records.map { |r| Indexer::IndexResult.success(r) }.to_a
        expectation = expect(@indexer).to receive(:index).with(@records)
        expected_results.each do |result|
          expectation.and_yield(result)
        end
        job = HarvestAndIndexJob.new(source_config: @source_config, index_config: @index_config, metadata_mapper: @metadata_mapper, persistence_manager: @persistence_mgr)
        actual_results = []
        job.harvest_and_index do |result|
          actual_results << result
        end
        expect(actual_results).to eq(expected_results)
      end

      it 'passes from and until times (if present) to harvest task' do
        from_time = Time.utc(1999, 12, 31, 11, 59, 59)
        until_time = Time.utc(2001, 12, 31, 11, 59, 59)
        @harvest_task = instance_double(Harvester::HarvestTask)
        allow(@harvest_task).to receive(:from_time) { from_time }
        allow(@harvest_task).to receive(:until_time) { until_time }
        allow(@harvest_task).to receive(:query_uri) { URI('http://source.example.org/') }
        expect(@harvest_task).to receive(:harvest_records) { @records }
        expect(@source_config).to receive(:create_harvest_task).with(from_time: from_time, until_time: until_time) { @harvest_task }
        allow(@indexer).to receive(:index).with(@records)
        job = HarvestAndIndexJob.new(
          source_config: @source_config,
          index_config: @index_config,
          metadata_mapper: @metadata_mapper,
          persistence_manager: @persistence_mgr,
          from_time: from_time,
          until_time: until_time
        )
        job.harvest_and_index
      end

      describe 'persistence' do
        before(:each) do
          @from_time = Time.utc(2014, 1, 1)
          @until_time = Time.utc(2016, 1, 1)

          @job = HarvestAndIndexJob.new(
            source_config: @source_config,
            index_config: @index_config,
            metadata_mapper: @metadata_mapper,
            persistence_manager: @persistence_mgr,
            from_time: @from_time,
            until_time: @until_time
          )

          @query_url = URI('http://source.example.org/')
          allow(@harvest_task).to receive(:from_time) { @from_time }
          allow(@harvest_task).to receive(:until_time) { @until_time }
          allow(@harvest_task).to receive(:query_uri) { @query_url }

          @harvest_job_id = 17
          allow(@persistence_mgr).to receive(:begin_harvest_job).with(any_args).and_return(@harvest_job_id)

          @index_job_id = 19
          allow(@persistence_mgr).to receive(:begin_index_job).with(any_args).and_return(@index_job_id)

          allow(@indexer).to receive(:index).with(@records)
        end

        it 'begins/ends a harvest job' do
          expect(@persistence_mgr).to receive(:begin_harvest_job).with(from_time: @from_time, until_time: @until_time, query_url: @query_url).and_return(@harvest_job_id)
          expect(@persistence_mgr).to receive(:end_harvest_job).with(harvest_job_id: @harvest_job_id, status: Indexer::IndexStatus::COMPLETED)
          @job.harvest_and_index
        end

        it 'begins/ends an index job' do
          expect(@persistence_mgr).to receive(:begin_index_job).with(harvest_job_id: @harvest_job_id, solr_url: @index_config.uri) { @index_job_id }
          expect(@persistence_mgr).to receive(:end_index_job).with(index_job_id: @index_job_id, status: Indexer::IndexStatus::COMPLETED)
          @job.harvest_and_index
        end

        it 'sets the harvest status to failed in event of a pre-indexing failure' do
          e = Exception.new('oops')
          expect(@harvest_task).to receive(:harvest_records).and_raise(e)
          expect(@persistence_mgr).to receive(:end_harvest_job).with(harvest_job_id: @harvest_job_id, status: Indexer::IndexStatus::FAILED)
          expect { @job.harvest_and_index }.to raise_error(e)
        end

        it 'sets the index status to failed in event of an indexing failure' do
          e = Exception.new('oops')
          expect(@indexer).to receive(:index).and_raise(e)
          expect(@persistence_mgr).to receive(:end_index_job).with(index_job_id: @index_job_id, status: Indexer::IndexStatus::FAILED)
          expect { @job.harvest_and_index }.to raise_error(e)
        end

        it 'sets the harvest status to successful in event of an indexing failure' do
          e = Exception.new('oops')
          expect(@indexer).to receive(:index).and_raise(e)
          expect(@persistence_mgr).to receive(:end_harvest_job).with(harvest_job_id: @harvest_job_id, status: Indexer::IndexStatus::COMPLETED)
          expect { @job.harvest_and_index }.to raise_error(e)
        end

        it 'creates a harvested_record for each harvested record'
        it 'creates an indexed_record for each indexed record'

        it 'logs overall job failures'
        it 'logs each successfully indexed record'
        it 'logs each successfully deleted record'
        it 'logs each failed record'
      end
    end
  end
end

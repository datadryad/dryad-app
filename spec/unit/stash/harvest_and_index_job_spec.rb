require 'spec_helper'
require 'stash/harvest_and_index_job'

module Stash
  describe HarvestAndIndexJob do
    describe '#initialize' do
      it 'creates a harvest task' do
        source_config = instance_double(Harvester::SourceConfig)
        from_time = Time.utc(1914, 8, 4, 23)
        until_time = Time.utc(1918, 11, 11, 10)
        harvest_task = instance_double(Harvester::HarvestTask)
        expect(source_config).to receive(:create_harvest_task).with(from_time: from_time, until_time: until_time) { harvest_task }

        index_config = instance_double(Indexer::IndexConfig)
        allow(index_config).to receive(:create_indexer)

        metadata_mapper = instance_double(Indexer::MetadataMapper)

        job = HarvestAndIndexJob.new(source_config: source_config, index_config: index_config, metadata_mapper: metadata_mapper, from_time: from_time, until_time: until_time)
        expect(job.harvest_task).to equal(harvest_task)
      end

      it 'creates an indexer' do
        source_config = instance_double(Harvester::SourceConfig)
        allow(source_config).to receive(:create_harvest_task)

        indexer = instance_double(Indexer::Indexer)

        index_config = instance_double(Indexer::IndexConfig)
        expect(index_config).to receive(:create_indexer) { indexer }

        metadata_mapper = instance_double(Indexer::MetadataMapper)

        job = HarvestAndIndexJob.new(source_config: source_config, index_config: index_config, metadata_mapper: metadata_mapper)
        expect(job.indexer).to equal(indexer)
      end
    end

    describe '#harvest_and_index' do
      it 'harvests and indexes records' do
        source_config = instance_double(Harvester::SourceConfig)
        harvest_task = instance_double(Harvester::HarvestTask)
        expect(source_config).to receive(:create_harvest_task) { harvest_task }

        indexer = instance_double(Indexer::Indexer)
        index_config = instance_double(Indexer::IndexConfig)
        expect(index_config).to receive(:create_indexer) { indexer }

        records = [].lazy
        expect(harvest_task).to receive(:harvest_records) { records }
        expect(indexer).to receive(:index).with(records)

        metadata_mapper = instance_double(Indexer::MetadataMapper)

        job = HarvestAndIndexJob.new(source_config: source_config, index_config: index_config, metadata_mapper: metadata_mapper)
        job.harvest_and_index
      end

      it 'logs each successfully indexed record'

      it 'logs each successfully deleted record'

      it 'logs each failed record'

      it 'yields the submission time and status (completed/failed) for each record'
    end
  end
end

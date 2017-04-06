require 'spec_helper'

module Stash
  module Indexer
    describe NullIndexConfig do

      attr_reader :config
      attr_reader :mapper

      before(:each) do
        @config = NullIndexConfig.new
        @mapper = instance_double(MetadataMapper)
      end

      it 'builds an indexer' do
        expect(config.create_indexer(metadata_mapper: mapper)).to be_an(Indexer)
      end

      it 'is describable' do
        expect(config.description).to be_a(String)
      end

      it 'returns a successful result for each record' do
        now = Time.now
        allow(Time).to receive(:now) { now }
        begin
          indexer = config.create_indexer(metadata_mapper: mapper)
          records = Array.new(3) do |i|
            record = instance_double(Stash::Harvester::HarvestedRecord)
            allow(record).to receive(:identifier) { "record#{i}" }
            record
          end
          expected_yield = records.map { |r| IndexResult.success(r) }
          expect { |b| indexer.index(records.lazy, &b) }.to yield_successive_args(*expected_yield)
        ensure
          allow(Time).to receive(:now).and_call_original
        end
      end
    end
  end
end

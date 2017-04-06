require 'spec_helper'

module Stash
  module Indexer
    describe Indexer do
      describe '#index' do
        it 'is abstract' do
          metadata_mapper = instance_double(MetadataMapper)
          indexer = Indexer.new(metadata_mapper: metadata_mapper)
          harvested_records = instance_double(Enumerator::Lazy)
          expect { indexer.index(harvested_records) }.to raise_error(NoMethodError)
        end
      end
    end
  end
end

require 'spec_helper'

module Stash
  module Indexer
    describe Indexer do
      describe '#index' do
        it 'is abstract' do
          indexer = Indexer.new
          harvested_records = instance_double(Enumerator::Lazy)
          expect { indexer.index(harvested_records) }.to raise_error(NoMethodError)
        end
      end
    end
  end
end

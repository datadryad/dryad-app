require 'spec_helper'

module Stash
  module Indexer
    describe MetadataMapper do
      describe '#to_index_document' do
        it 'is abstract' do
          wrapped_metadata = instance_double(Stash::Wrapper::StashWrapper)
          mapper = MetadataMapper.new
          expect { mapper.to_index_document(wrapped_metadata) }.to raise_error(NoMethodError)
        end
      end
    end
  end
end

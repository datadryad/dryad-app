require 'spec_helper'

module Stash
  module Indexer
    module DataciteDefault
      describe Mapper do
        before(:each) do
          @mapper = Mapper.new
        end
        it 'extracts from wrapper with clean namespacing' do
          xml = File.read('spec/data/wrapped_datacite/wrapped-datacite-example.xml')
          wrapper = Stash::Wrapper::StashWrapper.parse_xml(xml)
          doc = @mapper.to_index_document(wrapper)
          expect(doc).not_to be_nil
        end

        it 'extracts from wrapper with messy Merritt namepacing' do
          xml = File.read('spec/data/wrapped_datacite/wrapped-datacite-merritt.xml')
          wrapper = Stash::Wrapper::StashWrapper.parse_xml(xml)
          doc = @mapper.to_index_document(wrapper)
          expect(doc).not_to be_nil
        end
      end
    end
  end
end

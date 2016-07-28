require 'spec_helper'

module Stash
  module Wrapper
    describe StashFile do
      describe '#initialize' do
        attr_reader :params
        before(:each) do
          @params = {
            pathname: 'foo.txt',
            size_bytes: 12_345,
            mime_type: 'text/plain'
          }
        end

        it 'sets attributes from parameters'

        it 'requires a pathname'
        it 'rejects a nil pathname'
        it 'rejects an empty pathname'
        it 'rejects a blank pathname'

        it 'requires size_bytes'
        it 'rejects a nil size_bytes'
        it 'rejects a non-integer size_bytes'
        it 'rejects a non-numeric size_bytes'

        it 'accepts a standard MIME type'
        it 'accepts a non-standard MIME type'
        it 'fails if mime_type isn\'t a MIME type'
        it 'parses a nil mime-type as nil'
      end
    end
  end
end

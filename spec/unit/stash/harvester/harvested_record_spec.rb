require 'spec_helper'

module Stash
  module Harvester
    describe HarvestedRecord do

      before(@each) do
        @record = HarvestedRecord.new(identifier: 'an identifier', timestamp: Time.now.utc)
      end

      describe '#initialize' do
        it 'sets the identifier'
        it 'sets the timestamp'
        it 'sets the deleted flag'
        it 'requires an identifier'
        it 'requires a timestamp'
        it 'defaults to deleted=false'
      end

      describe '#content' do
        it 'is abstract' do
          expect { @record.content }.to raise_error(NoMethodError)
        end
      end
    end
  end
end

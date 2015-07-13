require 'spec_helper'

module Stash
  module Harvester
    describe HarvestedRecord do

      before(@each) do
        @record = HarvestedRecord.new(identifier: 'an identifier', timestamp: Time.now.utc)
      end

      describe '#content' do
        it 'is abstract' do
          expect { @record.content }.to raise_error
        end
      end
    end
  end
end

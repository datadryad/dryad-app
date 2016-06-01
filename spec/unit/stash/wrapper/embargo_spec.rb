require 'spec_helper'

module Stash
  module Wrapper
    describe Embargo do
      it 'validates its arguments'

      describe 'none' do
        it "returns a no-embargo #{Embargo}" do
          embargo = Embargo.none
          expect(embargo).to be_an(Embargo)
          expect(embargo.type).to eq(EmbargoType::NONE)
          expect(embargo.period).to eq('none')
          today = Date.today
          expect(embargo.start_date).to eq(today)
          expect(embargo.end_date).to eq(today)
        end
      end
    end
  end
end

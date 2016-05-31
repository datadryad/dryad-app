require 'spec_helper'

module Stash
  module Wrapper
    describe StashAdministrative do
      describe '#initialize' do
        it 'defaults to no embargo' do
          admin = StashAdministrative.new(
            version: Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
            license: License::CC_BY,
            inventory: Inventory.new(
              files: [
                StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain')
              ])
          )
          embargo = admin.embargo
          expect(embargo).to be_an(Embargo)
          expect(embargo.type).to eq(EmbargoType::NONE)
          expect(embargo.period).to eq('none')
          today = Date.today
          expect(embargo.start_date).to eq(today)
          expect(embargo.end_date).to eq(today)
        end
        
        it 'requires a version'
        it 'requires a valid version'

        it 'requires a license'
        it 'requires a valid license'
      end
    end
  end
end

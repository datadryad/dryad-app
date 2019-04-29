require 'db_spec_helper'

module StashDatacite
  describe Affiliation do
    describe :before_save do
      it 'strips long name whitespace' do
        affil =  StashDatacite::Affiliation.create(long_name: ' RCA Victor ')
        affil.save
        affil.reload
        expect(affil.long_name).to eq('RCA Victor')
      end
    end

    describe :smart_name do
      it 'returns empty string for nameless afiliations' do
        affil = StashDatacite::Affiliation.create
        expect(affil.smart_name).to eq('')
      end
      it 'prefers the short name' do
        affil = StashDatacite::Affiliation.create(short_name: 'BMG', long_name: 'Bertelsmann Music Group')
        expect(affil.smart_name).to eq('BMG')
      end
      it 'falls back to the long name' do
        affil = StashDatacite::Affiliation.create(long_name: 'Bertelsmann Music Group')
        expect(affil.smart_name).to eq('Bertelsmann Music Group')
      end
    end

    describe :fee_waivered? do
      before(:each) do
        @affil = StashDatacite::Affiliation.create(long_name: 'Bertelsmann Music Group', ror_id: '12345')
        @ror_org = Stash::Organization::Ror::Organization.new(id: '12345', name: 'Bertelsmann Music Group')
        allow_any_instance_of(Stash::Organization::Ror).to receive(:find_by_ror_id).and_return(@ror_org)
        allow(@affil).to receive(:fee_waiver_countries).and_return(['East Timor'])
      end

      it 'returns false if the affiliation has no ROR id' do
        @affil.ror_id = nil
        expect(@affil.fee_waivered?).to eql(false)
      end
      it 'returns false if the associated ROR record could not be found' do
        allow_any_instance_of(Stash::Organization::Ror).to receive(:find_by_ror_id).and_return(nil)
        expect(@affil.fee_waivered?).to eql(false)
      end
      it 'returns false if the associated ROR record does not specify a country' do
        expect(@affil.fee_waivered?).to eql(false)
      end
      it 'returns false if the associated ROR record\'s country is NOT in the fee waiver list' do
        @ror_org.country = { 'country_code' => 'NoW', 'country_name' => 'Nowhereland' }
        expect(@affil.fee_waivered?).to eql(false)
      end
      it 'returns true if the associated ROR record\'s country is in the fee waiver list' do
        @ror_org.country = { 'country_code' => 'TL', 'country_name' => 'East Timor' }
        expect(@affil.fee_waivered?).to eql(true)
      end
    end

    describe :country_name do
      before(:each) do
        @affil = StashDatacite::Affiliation.create(long_name: 'Bertelsmann Music Group', ror_id: '12345')
        @ror_org = Stash::Organization::Ror::Organization.new(id: '12345', name: 'Bertelsmann Music Group')
        allow_any_instance_of(Stash::Organization::Ror).to receive(:find_by_ror_id).and_return(@ror_org)
      end
      it 'returns the correct country_name when given a country object' do
        @ror_org.country = { 'country_code' => 'TL', 'country_name' => 'East Timor' }
        expect(@affil.country_name).to eql('East Timor')
      end
    end
  end
end

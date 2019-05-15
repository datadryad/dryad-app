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

    describe :from_long_name do
      before(:each) do
        allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)
      end

      it 'returns nil if no name is provided' do
        expect(StashDatacite::Affiliation.from_long_name(nil)).to eql(nil)
      end
      it 'returns the correct affiliation if the name exists in the DB' do
        affil = StashDatacite::Affiliation.create(long_name: 'Test Affiliation')
        expect(StashDatacite::Affiliation.from_long_name('test affiliation')).to eql(affil)
      end
      it 'does NOT do a ROR lookup if the record already has a ROR id' do
        affil = StashDatacite::Affiliation.create(long_name: 'Test Affiliation', ror_id: '123')
        expect(StashDatacite::Affiliation).not_to receive(:find_by_ror_long_name).with('test affiliation')
        expect(StashDatacite::Affiliation.from_long_name('test affiliation')).to eql(affil)
      end
      it 'does do a ROR lookup if the record does NOT already have a ROR id' do
        affil = StashDatacite::Affiliation.create(long_name: 'Test Affiliation')
        expect(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).with('test affiliation')
        expect(StashDatacite::Affiliation.from_long_name('test affiliation')).to eql(affil)
      end
      it 'uses the long_name returned by ROR' do
        allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(id: '999', name: 'Foo')
        StashDatacite::Affiliation.create(long_name: 'Test Affiliation')
        expect(StashDatacite::Affiliation.from_long_name('test affiliation').long_name).to eql('Foo')
      end
    end
  end
end

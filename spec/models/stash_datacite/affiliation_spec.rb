# == Schema Information
#
# Table name: dcs_affiliations
#
#  id           :integer          not null, primary key
#  abbreviation :text(65535)
#  long_name    :text(65535)
#  short_name   :text(65535)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  ror_id       :string(191)
#
# Indexes
#
#  index_dcs_affiliations_on_long_name   (long_name)
#  index_dcs_affiliations_on_ror_id      (ror_id)
#  index_dcs_affiliations_on_short_name  (short_name)
#
require 'rails_helper'

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
      it 'shows the asterisk when asked' do
        affil = StashDatacite::Affiliation.create(long_name: 'Bertelsmann Music Group*')
        expect(affil.smart_name(show_asterisk: true)).to eq('Bertelsmann Music Group*')
      end
      it 'suppresses the asterisk by default' do
        affil = StashDatacite::Affiliation.create(long_name: 'Bertelsmann Music Group*')
        expect(affil.smart_name).to eq('Bertelsmann Music Group')
      end
    end

    describe :country_name do
      before(:each) do
        @affil = StashDatacite::Affiliation.create(long_name: 'Bertelsmann Music Group', ror_id: '12345')
        @ror_org = StashEngine::RorOrg.new(ror_id: '12345', name: 'Bertelsmann Music Group')
      end

      it 'returns the correct country_name when given a country object' do
        @ror_org.update(country: 'East Timor')
        expect(@affil.country_name).to eql('East Timor')
      end
    end

    describe :from_long_name do
      before(:each) do
        allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)
      end

      it 'returns nil if no name is provided' do
        expect(StashDatacite::Affiliation.from_long_name(long_name: nil)).to eql(nil)
      end

      it 'returns the correct affiliation if the name exists in the DB' do
        affil = StashDatacite::Affiliation.create(long_name: 'Test Affiliation')
        expect(StashDatacite::Affiliation).not_to receive(:find_by_ror_long_name)
        expect(StashDatacite::Affiliation.from_long_name(long_name: 'test affiliation')).to eql(affil)
      end

      it 'does NOT do a ROR lookup if the record already has a ROR id' do
        affil = StashDatacite::Affiliation.create(long_name: 'Test Affiliation', ror_id: '123')
        expect(StashDatacite::Affiliation).not_to receive(:find_by_ror_long_name)
        expect(StashDatacite::Affiliation.from_long_name(long_name: 'test affiliation')).to eql(affil)
      end

      it 'does a ROR lookup if the caller requests' do
        expect(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).with(long_name: 'test affiliation')
        test_affil = StashDatacite::Affiliation.from_long_name(long_name: 'test affiliation', check_ror: true)
        expect(test_affil.long_name).to eql('test affiliation*')
      end

    end

  end
end

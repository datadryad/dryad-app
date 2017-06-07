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
        affil =  StashDatacite::Affiliation.create
        expect(affil.smart_name).to eq('')
      end
      it 'prefers the short name' do
        affil =  StashDatacite::Affiliation.create(short_name: 'BMG', long_name: 'Bertelsmann Music Group')
        expect(affil.smart_name).to eq('BMG')
      end
      it 'falls back to the long name' do
        affil =  StashDatacite::Affiliation.create(long_name: 'Bertelsmann Music Group')
        expect(affil.smart_name).to eq('Bertelsmann Music Group')
      end
    end
  end
end

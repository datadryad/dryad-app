require 'ostruct'
require_relative '../../../../spec_helpers/factory_helper'
require 'byebug'

 module StashEngine
  RSpec.describe InternalDatum do

     before(:each) do
      @identifier = create(:identifier)
      @resource = create(:resource, identifier_id: @identifier.id)
    end

     context 'class methods' do

       describe :data_type do

         before(:each) do
          @doi = create(:internal_datum, identifier_id: @identifier.id, data_type: 'manuscriptNumber', value: '10.123/ABC123.567')
          @name1 = create(:internal_datum, identifier_id: @identifier.id, data_type: 'publicationName', value: 'Mad Magazine')
          @name2 = create(:internal_datum, identifier_id: @identifier.id, data_type: 'publicationName', value: 'Cracked')
        end

         it 'returns the correct records' do
          expect(StashEngine::InternalDatum.data_type('manuscriptNumber').length).to eql(1)
          expect(StashEngine::InternalDatum.data_type('publicationName').length).to eql(2)
        end

         it 'returns an empty collection if no records were matched' do
          expect(StashEngine::InternalDatum.data_type(nil).length).to eql(0)
          expect(StashEngine::InternalDatum.data_type('mismatchedDOI').length).to eql(0)
          expect(StashEngine::InternalDatum.data_type('u45hy945hg9ui').length).to eql(0)
        end

       end

       describe :allows_multiple do

         it 'returns true if the data_type is mismatchedDOI' do
          expect(StashEngine::InternalDatum.allows_multiple('mismatchedDOI')).to eq(true)
        end
        it 'returns true if the data_type is mismatchedDOI' do
          expect(StashEngine::InternalDatum.allows_multiple('duplicateItem')).to eq(true)
        end
        it 'returns true if the data_type is mismatchedDOI' do
          expect(StashEngine::InternalDatum.allows_multiple('formerManuscriptNumber')).to eq(true)
        end

         it 'returns false if the data_type is publicationName' do
          expect(StashEngine::InternalDatum.allows_multiple('publicationName')).to eq(false)
        end
        it 'returns false if the data_type is manuscriptNumber' do
          expect(StashEngine::InternalDatum.allows_multiple('manuscriptNumber')).to eq(false)
        end
        it 'returns false if the data_type is publicationISSN' do
          expect(StashEngine::InternalDatum.allows_multiple('publicationISSN')).to eq(false)
        end
        it 'returns false if the data_type is pubmedID' do
          expect(StashEngine::InternalDatum.allows_multiple('pubmedID')).to eq(false)
        end
        it 'returns false if the data_type is dansArchiveDate' do
          expect(StashEngine::InternalDatum.allows_multiple('dansArchiveDate')).to eq(false)
        end
        it 'returns false if the data_type is dansEditIRI' do
          expect(StashEngine::InternalDatum.allows_multiple('dansEditIRI')).to eq(false)
        end

         it 'returns false if the data_type is unknown' do
          expect(StashEngine::InternalDatum.allows_multiple('ejhirgiq3gi')).to eq(false)
          expect(StashEngine::InternalDatum.allows_multiple(nil)).to eq(false)
        end
      end
    end

   end
end

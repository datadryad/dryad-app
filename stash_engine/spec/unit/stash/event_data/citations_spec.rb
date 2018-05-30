require 'spec_helper'

module Stash
  module EventData
    describe Citations do

      before(:each) do
        @citations = Citations.new(doi: '54321/09876')
        fake_dc_result = [{ 'obj_id' => 1, 'test_name' => 'one_dcs' },
                          { 'obj_id' => 2, 'test_name' => 'two_dcs' }]
        allow(@citations).to receive(:datacite_query).and_return(fake_dc_result)

        fake_xref_result = [{ 'subj_id' => 2, 'test_name' => 'two_xref' },
                            { 'subj_id' => 3, 'test_name' => 'three_xref' }]
        allow(@citations).to receive(:crossref_query).and_return(fake_xref_result)
      end

      describe :initializes do
        it 'sets doi' do
          c = Citations.new(doi: '12345/67890')
          expect(c.doi).to eq('12345/67890')
        end

        it 'removes prefix from doi' do
          c = Citations.new(doi: 'doi:12345/67890')
          expect(c.doi).to eq('12345/67890')
        end
      end

      describe :results do
        it 'gets results as array' do
          expect(@citations.results).to be_kind_of(Array)
        end

        it 'deduplicates duplicate items (preferring datacite)' do
          expect(@citations.results.length).to eq(3)
          expect(@citations.results).to include('obj_id' => 2, 'test_name' => 'two_dcs')
        end

      end
    end
  end
end

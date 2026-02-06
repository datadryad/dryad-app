# == Schema Information
#
# Table name: stash_engine_counter_citations
#
#  id            :integer          not null, primary key
#  citation      :text(65535)
#  doi           :text(65535)
#  metadata      :json
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#
# Indexes
#
#  index_stash_engine_counter_citations_on_doi            (doi)
#  index_stash_engine_counter_citations_on_identifier_id  (identifier_id)
#
module StashEngine
  describe CounterCitation do

    before(:each) do
      @identifier = create(:identifier)
    end

    describe 'self.citation_metadata(doi:, stash_identifier:)' do
      it 'returns nil if citation unable to be generated' do
        doi = '10.1010/12345.67890'

        expect(Integrations::Doi).to receive_message_chain(:new, :citeproc_json).with(doi).and_return(nil)
        expect(CounterCitation.citation_metadata(doi: doi, stash_identifier: @identifier)).to be_nil
      end
    end

    describe '#raw_metadata' do
      it 'handles json parse errors' do
        stub_request(:get, %r{doi\.org/10\.1111%2Fmec\.13594})
          .with(
            headers: {
              'Accept' => 'application/citeproc+json',
              'Host' => 'doi.org',
              'User-Agent' => /.*/
            }
          ).to_return(status: 200, body: '<!DOCTYPE html><html><head></head><body>Awesome webpage instead.</body></html>', headers: {})
        expect(@citation).to be_nil
      end
    end

    context 'successful metadata checks' do

      before(:each) do
        stub_request(:get, %r{doi\.org/10\.1111%2Fmec\.13594})
          .with(
            headers: {
              'Accept' => 'application/citeproc+json',
              'Host' => 'doi.org',
              'User-Agent' => /.*/
            }
          ).to_return(status: 200, body: File.read(Rails.root.join('spec', 'fixtures', 'http_responses', 'datacite_response.json')), headers: {})
        doi = '10.1111/mec.13594'
        @citation = CounterCitation.citation_metadata(doi: doi, stash_identifier: @identifier)
      end

      describe '#journal' do
        it 'returns the journal from container-title' do
          expect(@citation.journal).to eq('Molecular Ecology')
        end
      end

      describe '#html_citation' do
        it 'contains the journal name' do
          expect(@citation.citation).to include('Molecular Ecology')
        end
      end
    end
  end
end

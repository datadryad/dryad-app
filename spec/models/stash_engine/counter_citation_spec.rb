# == Schema Information
#
# Table name: stash_engine_counter_citations
#
#  id            :integer          not null, primary key
#  citation      :text(65535)
#  doi           :text(65535)
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

        expect(Stash::DataciteMetadata).to receive(:new).with(doi: doi).and_return({ html_citation: nil }.to_ostruct)
        expect(CounterCitation.citation_metadata(doi: doi, stash_identifier: @identifier)).to be_nil
      end
    end
  end
end

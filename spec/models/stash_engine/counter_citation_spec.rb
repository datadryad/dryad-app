module StashEngine
  describe CounterCitation do

    before(:each) do
      @identifier = create(:identifier)
    end

    describe 'self.citation_metadata(doi:, stash_identifier:)' do
      it 'returns nil if citation unable to be generated' do
        doi = '10.1010/12345.67890'

        expect(Stash::DataciteMetadata).to receive(:new).with(doi: doi).and_return({html_citation: nil}.to_ostruct)
        expect(CounterCitation.citation_metadata(doi: doi, stash_identifier: @identifier)).to be_nil
      end
    end
  end
end

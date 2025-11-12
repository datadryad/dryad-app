module StashDatacite
  RSpec.describe AffiliationsController, type: :request do
    include Mocks::CurationActivity
    include Mocks::RSolr

    before(:each) do
      neuter_curation_callbacks!
    end

    describe 'get affiliations' do
      it 'will retrive an affiliation through autocomplete' do
        ror_org = create(:ror_org)
        mock_rors_solr!(include_rors: [ror_org])

        response_code = get "/stash_datacite/affiliations/autocomplete?query=#{ror_org.name}"
        expect(response_code).to eq(200)

        ror_result = JSON.parse(response.body)
        expect(ror_result.size).to eq(1)
        expect(ror_result.first['name']).to eq(ror_org.name)
      end

      it 'will force an exact-match affiliation to be before other matches, regardless of alphabetical order' do
        ror_org = create(:ror_org)
        ror_org2 = create(:ror_org, name: "#{ror_org.name} the Second")

        mock_rors_solr!(include_rors: [ror_org, ror_org2])

        response_code = get "/stash_datacite/affiliations/autocomplete?query=#{ror_org.name}"
        expect(response_code).to eq(200)

        ror_result = JSON.parse(response.body)
        expect(ror_result.size).to eq(2)
        expect(ror_result.first['name']).to eq(ror_org.name)
        expect(ror_result.second['name']).to eq(ror_org2.name)
      end
    end

  end
end

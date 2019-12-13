require 'rails_helper'
require 'uri'
require_relative '../stash_api/helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
require 'digest'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashDatacite
  RSpec.describe AffiliationsController, type: :request do

    include Mocks::Ror
    include Mocks::CurationActivity

    before(:each) do
      neuter_curation_callbacks!
    end

    describe 'get affiliations' do
      it 'will retrive an affiliation through autocomplete' do
        stub_ror_name_lookup(name: 'BOGUS_ROR_NAME')
        response_code = get '/stash_datacite/affiliations/autocomplete?term=BOGUS_ROR_NAME'
        expect(response_code).to eq(200)

        ror_result = JSON.parse(response.body)
        expect(ror_result.size).to eq(2)
      end

      it 'will force an exact-match affiliation to be before other matches, regardless of alphabetical order' do
        stub_ror_name_lookup(name: 'ZZZZ Name')
        response_code = get '/stash_datacite/affiliations/autocomplete?term=ZZZZ'
        expect(response_code).to eq(200)

        autocomplete_result = JSON.parse(response.body)
        expect(autocomplete_result[0]['long_name']).to eq('ZZZZ Name')
      end
    end

  end
end

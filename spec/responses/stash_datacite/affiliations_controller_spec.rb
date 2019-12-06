require 'rails_helper'
require 'uri'
# require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
require 'digest'
# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashDatacite
  RSpec.describe AffiliationsController, type: :request do

    include Mocks::Ror
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::CurationActivity
    include Mocks::Repository
    include Mocks::UrlUpload

    before(:each) do
      neuter_curation_callbacks!
      mock_ror!
    end

    describe 'get affiliations' do
      it 'will retrive an affiliation' do
        response_code = get "/stash_datacite/affiliations/autocomplete?term=ucla"
        expect(response_code).to eq(200)
      end
    end
    
  end
end

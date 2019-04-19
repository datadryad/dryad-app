require 'rails_helper'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
# rubocop:disable Metrics/BlockLength
module StashApi
  RSpec.describe DatasetsController, type: :request do

    include Mocks::Ror

    before(:all) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    # test creation of a new dataset
    describe '#create' do
      before(:each) do
        mock_ror!
        @meta = Fixtures::StashApi::Metadata.new
        @meta.make_minimal
      end

      it 'creates a new dataset from minimal metadata (title, author info, abstract)' do
        # the following works for post with headers
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        output = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(201)
        expect(%r{doi:10.5072/dryad\..{8}}).to match(output[:identifier])
        hsh = @meta.hash
        expect(hsh[:title]).to eq(output[:title])
        expect(hsh[:abstract]).to eq(output[:abstract])
        in_author = hsh[:authors].first
        out_author = output[:authors].first
        expect(in_author).to eq(out_author)
      end

      it 'creates a new basic dataset with a placename' do
        @meta.add_place
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        output = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(201)

        # check it against the database
        @stash_id = StashEngine::Identifier.find(output[:id])
        @resource = @stash_id.resources.first
        expect(@resource.geolocations.first.geolocation_place.geo_location_place).to eq(@meta.hash[:locations].first[:place])

        # check it against the return json
        expect(output[:locations].first[:place]).to eq(@meta.hash[:locations].first[:place])
      end

    end
  end
end
# rubocop:enable Metrics/BlockLength

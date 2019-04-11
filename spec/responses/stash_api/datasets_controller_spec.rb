require 'rails_helper'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe GeneralController, type: :request do

    before(:all) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    # test creation of a new dataset
    describe '#create' do
      before(:each) do
        @meta = Fixtures::StashApi::Metadata.new
        @meta.make_minimal
      end

      it 'creates a new dataset from minimal metadata (title, author info, abstract)' do
        # the following works for post with headers
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        output = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(201)
        expect(/doi:10\.5072\/dryad\..{8}/).to match(output[:identifier])
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

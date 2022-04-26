require 'rails_helper'
require_relative 'stash_api/helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe ApiController, type: :request do
    before(:all) do
      host! 'my.example.org'
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    after(:all) do
      @user.destroy
      @doorkeeper_application.destroy
    end

    describe '#test' do
      it 'returns welcome message and authenticated user id for good token' do
        post '/api/v2/test', headers: default_authenticated_headers
        hsh = response_body_hash
        expect(/Welcome application owner.+$/).to match(hsh[:message])
        expect(@user.id).to eql(hsh[:user_id])
      end

      it 'returns 401 unauthorized for non-authenticated user' do
        response_code = post '/api/v2/test', headers: default_json_headers
        expect(response_code).to eq(401) # unauthorized
        expect(/invalid_token/).to match(response.headers['WWW-Authenticate'])
      end
    end

    describe '#index' do
      it 'has a HATEOAS link to the main entry into API, the datasets list' do
        get '/api/v2/', headers: default_json_headers
        hsh = response_body_hash
        expect(hsh['_links']['stash:datasets']['href']).to eql('/api/v2/datasets')
      end
    end
  end
end

require 'rails_helper'
require_relative 'helpers'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec

# rubocop:disable Metrics/BlockLength
module StashApi
  RSpec.describe GeneralController, type: :request do

    describe 'authenticated' do
      before(:all) do
        @user = create(:user, role: 'superuser')
        @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                         owner_id: @user.id, owner_type: 'StashEngine::User')
        setup_access_token(doorkeeper_application: @doorkeeper_application)
      end

      describe '#test' do
        it 'returns welcome message and authenticated user id for good token' do
          post "/api/test", nil, default_authenticated_headers
          hsh = response_body_hash
          expect(/Welcome application owner.+$/).to match(hsh[:message])
          expect(@user.id).to eql(hsh[:user_id])
        end

        it 'returns 401 unauthorized for non-authenticated user' do
          response_code = post "/api/test", nil, default_json_headers
          expect(response_code).to eq(401) # unauthorized
          expect(/invalid_token/).to match(response.headers['WWW-Authenticate'])
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

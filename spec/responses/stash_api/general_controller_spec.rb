require 'rails_helper'
require 'rest-client'

RSpec.configure do |config|
  config.render_views
end

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec

# rubocop:disable Metrics/BlockLength
module StashApi

  RSpec.describe GeneralController, type: :request do

    before(:all) do
      @user = create(:user, role: 'superuser')
      # the factorybot for this is ripped from the doorkeeper tests
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                       owner_id: @user.id, owner_type: 'StashEngine::User')
      @response = post "/oauth/token",
                       { grant_type: 'client_credentials', client_id: @doorkeeper_application.uid, client_secret: @doorkeeper_application.secret },
                       { "ACCEPT" => "application/json",  "Content-Type" => "application/x-www-form-urlencoded;charset=UTF-8" }
      byebug
    end

    describe 'test' do
      it 'is fun' do
        expect(true).to eq(true)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

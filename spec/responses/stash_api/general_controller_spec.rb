require 'rails_helper'
require_relative 'helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe GeneralController, type: :request do

    include Mocks::CurationActivity

    before(:all) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    # this is the general index of datasets
    describe '#index' do

      before(:each) do
        neuter_curation_callbacks!

        @users = Array.new(5) { create(:user) }
        @identifiers = []

        0.upto(4) do |i|
          @identifiers << create(:identifier) do |iden|
            @res = iden.resources.create(attributes_for(:resource, :submitted, user_id: @users[i].id))
            @res.descriptions.create(attributes_for(:description))
            @res.authors.create(attributes_for(:author, author_first_name: @users[i].first_name,
                                               author_last_name: @users[i].last_name,
                                               author_email: @users[i].email))
          end
        end
        @res = @identifiers.map { |id| id.resources.first }
        @res[0].curation_activities.create(attributes_for(:curation_activity, :published))
        @res[1].curation_activities.create(attributes_for(:curation_activity, :embargoed))
        @res[2].curation_activities.create(attributes_for(:curation_activity, :submitted))
        @res[3].curation_activities.create(attributes_for(:curation_activity, :action_required))
        @res[4].curation_activities.create(attributes_for(:curation_activity, :curation))
        byebug
      end

      it 'is a placeholder for now' do
        expect(true).to eql(true)
      end

    end

    describe '#test' do
      it 'returns welcome message and authenticated user id for good token' do
        post '/api/test', nil, default_authenticated_headers
        hsh = response_body_hash
        expect(/Welcome application owner.+$/).to match(hsh[:message])
        expect(@user.id).to eql(hsh[:user_id])
      end

      it 'returns 401 unauthorized for non-authenticated user' do
        response_code = post '/api/test', nil, default_json_headers
        expect(response_code).to eq(401) # unauthorized
        expect(/invalid_token/).to match(response.headers['WWW-Authenticate'])
      end
    end
  end
end

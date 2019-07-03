require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
# rubocop:disable Metrics/BlockLength, Metrics/ModuleLength
module StashApi
  RSpec.describe VersionsController, type: :request do

    include Mocks::Ror
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::CurationActivity
    include Mocks::Repository

    before(:all) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    # test creation of a new dataset
    describe '#index' do
      before(:each) do
        neuter_curation_callbacks!
        mock_ror!

        @tenant_ids = StashEngine::Tenant.all.map(&:tenant_id)

        @user1 = create(:user, tenant_id: @tenant_ids.first, role: 'user')

        @identifier = create(:identifier)

        @resources = [create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifier.id),
                      create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifier.id)]

        @curation_activities = [[create(:curation_activity, resource: @resources[0], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[0], status: 'curation'),
                                 create(:curation_activity, resource: @resources[0], status: 'published')]]

        @curation_activities << [create(:curation_activity, resource: @resources[1], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[1], status: 'curation')]

        # be sure versions are set correctly, because creating them manually like this doesn't ensure it
        @resources[0].stash_version.update(version: 1)
        @resources[1].stash_version.update(version: 2)
      end

      it 'shows all versions to a superuser' do
        response_code = get "/api/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_authenticated_headers
        expect(response_code).to eq(200)
        expect(response_body_hash['total']).to eq(2)
        my_versions = response_body_hash['_embedded']['stash:versions']

        0.upto(1) do |i|
          expect(my_versions[i]['title']).to eq(@resources[i].title)
          expect(my_versions[i]['versionNumber']).to eq(@resources[i].stash_version.version)
        end
      end

      it 'shows all versions to the owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                          owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_json_headers.merge(
            'Content-Type' =>  'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
          )

        expect(response_code).to eq(200)
        expect(response_body_hash['total']).to eq(2)
        my_versions = response_body_hash['_embedded']['stash:versions']

        0.upto(1) do |i|
          expect(my_versions[i]['title']).to eq(@resources[i].title)
          expect(my_versions[i]['versionNumber']).to eq(@resources[i].stash_version.version)
        end
      end

      it 'shows only 1st version to a random user' do
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'user')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                          owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_json_headers.merge(
            'Authorization' => "Bearer #{access_token}"
        )

        expect(response_code).to eq(200)
        expect(response_body_hash['total']).to eq(1)
        my_versions = response_body_hash['_embedded']['stash:versions']

        expect(my_versions.length).to eq(1)
        expect(my_versions[0]['title']).to eq(@resources[0].title)
        expect(my_versions[0]['versionNumber']).to eq(@resources[0].stash_version.version)
      end

      it 'only shows only 1st version to non-logged-in user' do
        response_code = get "/api/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_json_headers

        expect(response_code).to eq(200)
        expect(response_body_hash['total']).to eq(1)
        my_versions = response_body_hash['_embedded']['stash:versions']

        expect(my_versions.length).to eq(1)
        expect(my_versions[0]['title']).to eq(@resources[0].title)
        expect(my_versions[0]['versionNumber']).to eq(@resources[0].stash_version.version)
      end

      it 'shows both versions to an admin for this tenant' do
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'admin')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                          owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_json_headers.merge(
            'Authorization' => "Bearer #{access_token}"
        )

        expect(response_code).to eq(200)
        expect(response_body_hash['total']).to eq(2)
        my_versions = response_body_hash['_embedded']['stash:versions']

        expect(my_versions.length).to eq(2)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/ModuleLength

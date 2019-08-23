require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
require 'stash/download/version'

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

    # set up some versions with different curation statuses (visibility)
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

    # test creation of a new dataset
    describe '#index' do

      it 'shows all versions to a superuser' do
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_authenticated_headers
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
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_json_headers.merge(
          'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
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
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_json_headers.merge(
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
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_json_headers

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
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions", {}, default_json_headers.merge(
          'Authorization' => "Bearer #{access_token}"
        )

        expect(response_code).to eq(200)
        expect(response_body_hash['total']).to eq(2)
        my_versions = response_body_hash['_embedded']['stash:versions']

        expect(my_versions.length).to eq(2)
      end
    end

    # shows a version by the version ID (not version number) which can be obtained from the index action above
    describe '#show' do

      it 'shows published versions to non-users' do
        response_code = get "/api/v2/versions/#{@resources[0].id}", {}, default_json_headers
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h['title']).to eq(@resources[0].title)
        expect(h['abstract']).to eq(@resources[0].descriptions.where(description_type: 'abstract').first.description)
        expect(h['versionNumber']).to eq(@resources[0].stash_version.version)
      end

      it "doesn't show unpublished version to non-user" do
        response_code = get "/api/v2/versions/#{@resources[1].id}", {}, default_json_headers
        expect(response_code).to eq(404)
      end

      it "doesn't show unpublished version to random unauthorized user" do
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'user')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/versions/#{@resources[1].id}", {}, default_json_headers.merge(
          'Authorization' => "Bearer #{access_token}"
        )
        expect(response_code).to eq(404)
      end

      it 'shows anything existing to a superuser' do
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'superuser')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/versions/#{@resources[1].id}", {}, default_json_headers.merge(
          'Authorization' => "Bearer #{access_token}"
        )
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h['title']).to eq(@resources[1].title)
        expect(h['abstract']).to eq(@resources[1].descriptions.where(description_type: 'abstract').first.description)
        expect(h['versionNumber']).to eq(@resources[1].stash_version.version)
      end

      it 'shows stuff to admin from the same tenant' do
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'admin')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/versions/#{@resources[1].id}", {}, default_json_headers.merge(
          'Authorization' => "Bearer #{access_token}"
        )
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h['title']).to eq(@resources[1].title)
        expect(h['abstract']).to eq(@resources[1].descriptions.where(description_type: 'abstract').first.description)
        expect(h['versionNumber']).to eq(@resources[1].stash_version.version)
      end

      it 'returns 404 for non-existant resource, also' do
        response_code = get "/api/v2/versions/#{@resources[1].id + 100}", {}, default_json_headers
        expect(response_code).to eq(404)
      end

    end

    # downloads contents by version id if authorized and able to do so, note the actual download is streamed by
    # another class and will mock it for now since this all depends on Merritt overall.
    # Note: doesn't have json return, but a file is returned.
    describe '#download' do
      before(:each) do
        @resources[0].update(publication_date: Time.new - 24.hours)
        @resources[0].current_state = 'submitted' # has to show submitted to merritt in order to download
        # callbacks or something weird are adding states for this resource so, add published again as final state
        create(:curation_activity, resource: @resources[0], status: 'published')

        @resources[1].current_state = 'submitted' # has to show submitted to merritt in order to download
        allow_any_instance_of(Stash::Download::Version).to receive(:download) do |o|
          # o is the object instance and cc is the controller context
          o.cc.response.headers['Content-Type'] = 'text/plain'
          o.cc.response.headers['Content-Disposition'] = 'inline' # normally attachment for downloads, really, though
          o.cc.response.headers['Content-Length'] = 20
          o.cc.response.headers['Last-Modified'] = Time.now.httpdate
          o.cc.response_body = 'This file is awesome'
          # o.cc.render -- this isn't needed in the tests and causes a double-render which is different than the actual method
        end
      end

      it 'downloads a public version' do
        response_code = get "/api/v2/versions/#{@resources[0].id}/download", {}, {}
        expect(response_code).to eq(200)
        expect(response.body).to eq('This file is awesome')
      end

      it 'allows owner to download private, but submitted to Merritt version' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/versions/#{@resources[1].id}/download", {},
                            'Accept' => '*', 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{access_token}"
        expect(response_code).to eq(200)
        expect(response.body).to eq('This file is awesome')
      end

      it 'allows superuser to download private, but submitted to Merritt version' do
        response_code = get "/api/v2/versions/#{@resources[1].id}/download", {}, default_authenticated_headers.merge('Accept' => '*')
        expect(response_code).to eq(200)
        expect(response.body).to eq('This file is awesome')
      end

      it 'disallows random user from downloading non-public, but submitted version' do
        @user.update(role: 'user')
        response_code = get "/api/v2/versions/#{@resources[1].id}/download", {}, default_authenticated_headers.merge('Accept' => '*')
        expect(response_code).to eq(403)
      end

      it 'disallows nil user from downloading non-public, but submitted version' do
        response_code = get "/api/v2/versions/#{@resources[1].id}/download", {}, default_json_headers.merge('Accept' => '*')
        expect(response_code).to eq(403)
      end

      it 'allows admin to download private, but submitted to Merritt version' do
        @user.update(role: 'admin', tenant_id: @resources[1].tenant_id)
        response_code = get "/api/v2/versions/#{@resources[1].id}/download", {}, default_authenticated_headers.merge('Accept' => '*')
        expect(response_code).to eq(200)
        expect(response.body).to eq('This file is awesome')
      end

      it "disallows download if it's not submitted to Merritt" do
        @resources[1].current_state = 'in_progress'
        response_code = get "/api/v2/versions/#{@resources[1].id}/download", {}, default_authenticated_headers.merge('Accept' => '*')
        expect(response_code).to eq(403)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/ModuleLength

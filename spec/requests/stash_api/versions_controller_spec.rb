require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe VersionsController, type: :request do

    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::CurationActivity
    include Mocks::Repository
    include Mocks::Salesforce

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

    # set up some versions with different curation statuses (visibility)
    before(:each) do
      mock_salesforce!
      neuter_curation_callbacks!

      @tenant_ids = StashEngine::Tenant.all.map(&:tenant_id)

      @user1 = create(:user, tenant_id: @tenant_ids.first, role: 'user')

      @identifier = create(:identifier)

      @resources = [create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifier.id),
                    create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifier.id)]

      @curation_activities = [[create(:curation_activity, resource: @resources[0], status: 'in_progress', user_id: @user1.id),
                               create(:curation_activity, resource: @resources[0], status: 'curation', user_id: @user1.id),
                               create(:curation_activity, resource: @resources[0], status: 'published', user_id: @user1.id)]]

      @curation_activities << [create(:curation_activity, resource: @resources[1], status: 'in_progress', user_id: @user1.id),
                               create(:curation_activity, resource: @resources[1], status: 'curation', user_id: @user1.id)]

      # we get some crazy failures and it refused to update the resource because of ridiculous curation failures if user zero doesn't exist
      # Took me hours to figure out and really annoying.
      @sys_user = create(:user, id: 0, tenant_id: @tenant_ids.first, role: 'user', first_name: 'system user')

      # be sure versions are set correctly, because creating them manually like this doesn't ensure it
      @resources[0].stash_version.update(version: 1)
      @resources[1].stash_version.update(version: 2)
    end

    # test creation of a new dataset
    describe '#index' do

      it 'shows all versions to a superuser' do
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions", headers: default_authenticated_headers
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
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions",
                            headers: default_json_headers.merge(
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
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions",
                            headers: default_json_headers.merge(
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
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions", headers: default_json_headers

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
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions",
                            headers: default_json_headers.merge(
                              'Authorization' => "Bearer #{access_token}"
                            )

        expect(response_code).to eq(200)
        expect(response_body_hash['total']).to eq(2)
        my_versions = response_body_hash['_embedded']['stash:versions']

        expect(my_versions.length).to eq(2)
      end

      it 'shows both versions to an admin for this journal' do
        # set up @user2 as a journal admin, and @identifier as belonging to that journal
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: nil)
        journal = create(:journal)
        create(:journal_role, journal: journal, user: @user2, role: 'admin')
        create(:internal_datum, identifier_id: @identifier.id, data_type: 'publicationISSN', value: journal.single_issn)
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/versions",
                            headers: default_json_headers.merge(
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
        response_code = get "/api/v2/versions/#{@resources[0].id}", headers: default_json_headers
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h['title']).to eq(@resources[0].title)
        expect(h['abstract']).to eq(@resources[0].descriptions.where(description_type: 'abstract').first.description)
        expect(h['versionNumber']).to eq(@resources[0].stash_version.version)
      end

      it "doesn't show unpublished version to non-user" do
        response_code = get "/api/v2/versions/#{@resources[1].id}", headers: default_json_headers
        expect(response_code).to eq(404)
      end

      it "doesn't show unpublished version to random unauthorized user" do
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'user')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/versions/#{@resources[1].id}", headers: default_json_headers.merge(
          'Authorization' => "Bearer #{access_token}"
        )
        expect(response_code).to eq(404)
      end

      it 'shows anything existing to a superuser' do
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'superuser')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/versions/#{@resources[1].id}",
                            headers: default_json_headers.merge(
                              'Authorization' => "Bearer #{access_token}"
                            )
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h['title']).to eq(@resources[1].title)
        expect(h['abstract']).to eq(@resources[1].descriptions.where(description_type: 'abstract').first.description)
        expect(h['versionNumber']).to eq(@resources[1].stash_version.version)
        expect(h['sharingLink']).to match(/http/)
      end

      it 'shows what fields changed for v2 when both have been published' do
        create(:curation_activity, resource: @resources[1], status: 'published', user_id: @user1.id)
        response_code = get "/api/v2/versions/#{@resources[1].id}", headers: default_json_headers
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h[:changedFields]).to eq(%w[title authors abstract subjects funders])
      end

      it "wouldn't show changed fields for a first version" do
        response_code = get "/api/v2/versions/#{@resources[0].id}", headers: default_json_headers
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h[:changedFields]).to eq(%w[none])
      end

      it 'shows stuff to admin from the same tenant' do
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'admin')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/versions/#{@resources[1].id}",
                            headers: default_json_headers.merge(
                              'Authorization' => "Bearer #{access_token}"
                            )
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h['title']).to eq(@resources[1].title)
        expect(h['abstract']).to eq(@resources[1].descriptions.where(description_type: 'abstract').first.description)
        expect(h['versionNumber']).to eq(@resources[1].stash_version.version)
      end

      it 'returns 404 for non-existant resource, also' do
        response_code = get "/api/v2/versions/#{@resources[1].id + 100}", headers: default_json_headers
        expect(response_code).to eq(404)
      end

    end

    # downloads contents by version id if authorized and able to do so, note the actual download is streamed by
    # another class and will mock it for now since this all depends on Merritt overall.
    # Note: doesn't have json return, but a file is returned.
    describe '#download' do
      before(:each) do
        @resources[0].current_state = 'submitted' # has to show submitted to merritt in order to download
        @resources[0].update(publication_date: Time.new - 24.hours)
        # callbacks or something weird are adding states for this resource so, add published again as final state
        create(:curation_activity, resource: @resources[0], status: 'published')

        @resources[1].current_state = 'submitted' # has to show submitted to merritt in order to download

        allow_any_instance_of(Stash::Download::VersionPresigned).to receive('valid_resource?').and_return(true)
      end

      describe 'permissions' do
        before(:each) do
          allow_any_instance_of(Stash::Download::VersionPresigned).to receive(:download)
            .and_return({ status: 200, url: 'http://example.com/fun' }.with_indifferent_access)
        end

        it 'downloads a public version' do
          # some horrific callback or something that is untraceable keeps resetting file_view to false
          @resources[0].update(file_view: true)
          response_code = get "/api/v2/versions/#{@resources[0].id}/download"
          expect(response_code).to eq(302)
          expect(response.body).to include('http://example.com/fun')
          expect(response.body).to include('redirected')
        end

        it 'allows owner to download private, but submitted to Merritt version' do
          @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                     owner_id: @user1.id, owner_type: 'StashEngine::User')

          access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
          response_code = get "/api/v2/versions/#{@resources[1].id}/download",
                              headers: { 'Accept' => '*/*', 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{access_token}" }

          expect(response_code).to eq(302)
          expect(response.body).to include('http://example.com/fun')
          expect(response.body).to include('redirected')
        end

        it 'allows superuser to download private, but submitted to Merritt version' do
          response_code = get "/api/v2/versions/#{@resources[1].id}/download",
                              headers: default_authenticated_headers.merge('Accept' => '*/*')
          expect(response_code).to eq(302)
          expect(response.body).to include('http://example.com/fun')
          expect(response.body).to include('redirected')
        end

        it 'disallows random user from downloading non-public, but submitted version' do
          @user.update(role: 'user')
          response_code = get "/api/v2/versions/#{@resources[1].id}/download",
                              headers: default_authenticated_headers.merge('Accept' => '*/*')
          expect(response_code).to eq(404)
        end

        it 'disallows nil user from downloading non-public, but submitted version' do
          response_code = get "/api/v2/versions/#{@resources[1].id}/download", headers: default_json_headers.merge('Accept' => '*/*')
          expect(response_code).to eq(404)
        end

        it 'allows admin to download private, but submitted to Merritt version' do
          @user.update(role: 'admin', tenant_id: @resources[1].tenant_id)
          response_code = get "/api/v2/versions/#{@resources[1].id}/download", headers: default_authenticated_headers.merge('Accept' => '*/*')
          expect(response_code).to eq(302)
          expect(response.body).to include('http://example.com/fun')
          expect(response.body).to include('redirected')
        end

        it "disallows download if it's not submitted to Merritt" do
          @resources[1].current_state = 'in_progress'
          response_code = get "/api/v2/versions/#{@resources[1].id}/download", headers: default_authenticated_headers.merge('Accept' => '*/*')
          expect(response_code).to eq(404)
        end
      end

      describe 'response codes' do

        it 'handles 202 from Merritt presigned library' do
          allow_any_instance_of(Stash::Download::VersionPresigned).to receive(:download)
            .and_return({ status: 202, url: 'http://example.com/fun' }.with_indifferent_access)
          # some horrific callback or something that is untraceable keeps resetting file_view to false
          @resources[0].update(file_view: true)

          @resources[0].download_token.update(available: Time.new)

          response_code = get "/api/v2/versions/#{@resources[0].id}/download"
          expect(response_code).to eq(202)
          expect(response.body).to include('being assembled')
          expect(response.body).to include('less than a minute')
        end

        it 'handles 408 from Merritt presigned library' do
          allow_any_instance_of(Stash::Download::VersionPresigned).to receive(:download)
            .and_return({ status: 408 }.with_indifferent_access)
          # some horrific callback or something that is untraceable keeps resetting file_view to false
          @resources[0].update(file_view: true)

          @resources[0].download_token.update(available: Time.new)

          response_code = get "/api/v2/versions/#{@resources[0].id}/download"
          expect(response_code).to eq(503)
          expect(response.body).to include('Download Service Unavailable for this request')
        end

        it 'handles other random code from Merritt presigned library' do
          allow_any_instance_of(Stash::Download::VersionPresigned).to receive(:download)
            .and_return({ status: 417 }.with_indifferent_access)
          # some horrific callback or something that is untraceable keeps resetting file_view to false
          @resources[0].update(file_view: true)

          @resources[0].download_token.update(available: Time.new)

          response_code = get "/api/v2/versions/#{@resources[0].id}/download"
          expect(response_code).to eq(404)
          expect(response.body).to include('Not found')
        end

      end
    end
  end
end

require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'

# rubocop:disable Metrics/BlockLength, Metrics/ModuleLength
# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe FilesController, type: :request do

    include Mocks::Ror
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::CurationActivity
    include Mocks::Repository
    include Mocks::UrlUpload

    # set up some versions with different curation statuses (visibility)
    before(:each) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)

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

      @curation_activities << [create(:curation_activity, resource: @resources[1], status: 'in_progress')]

      @resources[0].current_resource_state.update(resource_state: 'submitted')
      @resources[1].current_resource_state.update(resource_state: 'in_progress')

      # be sure versions are set correctly, because creating them manually like this doesn't ensure it
      @resources[0].stash_version.update(version: 1)
      @resources[1].stash_version.update(version: 2)
      @file_path = Rails.root.join('spec/fixtures/http_responses/favicon.ico')
      @mime_type = 'image/vnd.microsoft.icon'
    end

    # working with files
    describe '#update' do
      it 'will add a file upload to the server and add metadata' do
        response_code = put "/api/datasets/#{CGI.escape(@identifier.to_s)}/files/#{CGI.escape(::File.basename(@file_path))}",
                            IO.read(@file_path), default_authenticated_headers.merge('Content-Type' => @mime_type)
        expect(response_code).to eq(201)
        hsh = response_body_hash
        expect(hsh['_links']['self']['href']).not_to be_nil
        expect(hsh['path']).to eq(::File.basename(@file_path))
        expect(hsh['size']).to eq(::File.size(@file_path))
        expect(hsh['mimeType']).to eq(@mime_type)
        expect(hsh['status']).to eq('created')
        expect(hsh['digest']).to eq(Digest::MD5.hexdigest(::File.read(@file_path)))
        expect(hsh['digestType']).to eq('md5')
      end

      it 'will not allow non-logged in to add a file' do
        response_code = put "/api/datasets/#{CGI.escape(@identifier.to_s)}/files/#{CGI.escape(::File.basename(@file_path))}",
                            IO.read(@file_path), default_json_headers.merge('Content-Type' => @mime_type)
        expect(response_code).to eq(401)
      end
    end

    describe '#show' do
      before(:each) do
        put "/api/datasets/#{CGI.escape(@identifier.to_s)}/files/#{CGI.escape(::File.basename(@file_path))}",
            IO.read(@file_path), default_authenticated_headers.merge('Content-Type' => @mime_type)
        hsh = response_body_hash
        @the_path = hsh['_links']['self']['href'] # this is a little weird, may need fixing
      end

      it 'shows the file info for a file that exists (superuser)' do
        response_code = get @the_path, {}, default_authenticated_headers
        expect(response_code).to eq(200)
        hsh = response_body_hash
        expect(hsh['path']).to eq(::File.basename(@file_path))
        expect(hsh['size']).to eq(::File.size(@file_path))
        expect(hsh['mimeType']).to eq(@mime_type)
        expect(hsh['status']).to eq('created')
        expect(hsh['digest']).to eq(Digest::MD5.hexdigest(::File.read(@file_path)))
        expect(hsh['digestType']).to eq('md5')
      end

      it "doesn't allow listing a file that should be hidden from the public" do
        response_code = get @the_path, {}, default_json_headers
        expect(response_code).to eq(404)
      end

      it 'shows non-public files to the owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get @the_path, {}, default_json_headers.merge(
          'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
        )
        expect(response_code).to eq(200)
        # return message tested elsewhere already
      end

      it 'shows non-public files to an admin for the same tenant' do
        @user1.update(role: 'admin')
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get @the_path, {}, default_json_headers.merge(
          'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
        )
        expect(response_code).to eq(200)
      end
    end

    describe '#index' do

      before(:each) do
        create_list(:file_upload, 25, resource_id: @resources[0].id)
        create_list(:file_upload, 4, resource_id: @resources[1].id)
      end

      it 'shows an index of files for a public dataset version' do
        response_code = get "/api/versions/#{@resources[0].id}/files", {}, default_authenticated_headers
        hsh = response_body_hash
        expect(response_code).to eq(200)
        expect(hsh['total']).to eq(25)
        item_hash = hsh['_embedded']['stash:files'].first
        %w[path size mimeType status].each do |i|
          expect(item_hash[i]).not_to be_nil
        end
      end

      it 'shows an index of files for a private dataset version to the superuser' do
        # check the superuser
        response_code = get "/api/versions/#{@resources[1].id}/files", {}, default_authenticated_headers
        hsh = response_body_hash
        expect(response_code).to eq(200)
        expect(hsh['total']).to eq(4)
      end

      it 'shows an index of files for a private dataset version to the owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/versions/#{@resources[1].id}/files", {}, default_json_headers.merge(
          'Authorization' => "Bearer #{access_token}"
        )
        hsh = response_body_hash
        expect(response_code).to eq(200)
        expect(hsh['total']).to eq(4)
      end

      it 'shows an index of files for a private dataset version to the admin' do
        @user.update(role: 'admin', tenant_id: @tenant_ids.first)
        response_code = get "/api/versions/#{@resources[1].id}/files", {}, default_authenticated_headers
        hsh = response_body_hash
        expect(response_code).to eq(200)
        expect(hsh['total']).to eq(4)
      end

      it "doesn't show private version's list of file to non-user" do
        response_code = get "/api/versions/#{@resources[1].id}/files", {}, default_json_headers
        expect(response_code).to eq(404)
      end

      it "doesn't show private versions list of files to a random user" do
        @user.update(role: 'user', tenant_id: @tenant_ids.first)
        response_code = get "/api/versions/#{@resources[1].id}/files", {}, default_authenticated_headers
        expect(response_code).to eq(404)
      end
    end

    describe '#destroy' do
      before(:each) do
        # make two lists of files for versions that are representative of how stuff works for versioning
        # with second version inheriting the files from the first showing as copied over internally
        @files = [create_list(:file_upload, 4, resource_id: @resources[0].id)]
        tmp = @files.first.map(&:amoeba_dup)
        tmp.each do |f|
          f.file_state = 'copied'
          f.resource_id = @resources[1].id
          f.save!
        end
        @files << tmp
      end

      it 'allows destroying file if superuser' do
        response_code = delete "/api/files/#{@files[1].first.id}", {}, default_authenticated_headers
        expect(response_code).to eq(200) # maybe this should be 202 for an item that is marked for deletion when we revise
        hsh = response_body_hash
        expect(hsh['status']).to eq('deleted')
      end

      it 'allows destroying file if owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = delete "/api/files/#{@files[1].first.id}", {}, default_authenticated_headers
          .merge('Authorization' => "Bearer #{access_token}")
        expect(response_code).to eq(200) # maybe this should be 202 for an item that is marked for deletion when we revise
        hsh = response_body_hash
        expect(hsh['status']).to eq('deleted')
      end

      it 'allows destroying file if admin for same tenant' do
        @user.update(role: 'admin', tenant_id: @tenant_ids.first)
        response_code = delete "/api/files/#{@files[1].first.id}", {}, default_authenticated_headers
        expect(response_code).to eq(200)
        hsh = response_body_hash
        expect(hsh['status']).to eq('deleted')
      end

      it 'blocks anonymous users from destroying files' do
        response_code = delete "/api/files/#{@files[1].first.id}", {}, default_json_headers
        expect(response_code).to eq(401)
      end

      it 'blocks destroying file if another regular user' do
        @user.update(role: 'user')
        response_code = delete "/api/files/#{@files[1].first.id}", {}, default_authenticated_headers
        expect(response_code).to eq(401)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/ModuleLength

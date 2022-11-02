require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe FilesController, type: :request do

    include Mocks::Aws
    include Mocks::CurationActivity
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::Repository
    include Mocks::Tenant
    include Mocks::UrlUpload

    # set up some versions with different curation statuses (visibility)
    before(:each) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)

      neuter_curation_callbacks!
      mock_aws!
      mock_tenant!

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
    # rubocop:disable Security/IoMethods
    describe '#update' do
      it 'will add a file upload to the server and add metadata' do
        response_code = put "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/files/#{CGI.escape(::File.basename(@file_path))}",
                            params: IO.read(@file_path),
                            headers: default_authenticated_headers.merge('Content-Type' => @mime_type)
        expect(response_code).to eq(201)
        hsh = response_body_hash
        expect(hsh['_links']['self']['href']).not_to be_nil
        expect(hsh['path']).to eq(::File.basename(@file_path))
        expect(hsh['mimeType']).to eq(@mime_type)
        expect(hsh['status']).to eq('created')
      end

      it 'will not allow non-logged in to add a file' do
        response_code = put "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/files/#{CGI.escape(::File.basename(@file_path))}",
                            params: IO.read(@file_path),
                            headers: default_json_headers.merge('Content-Type' => @mime_type)
        expect(response_code).to eq(401)
      end
    end

    describe '#show' do
      before(:each) do
        put "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/files/#{CGI.escape(::File.basename(@file_path))}",
            params: IO.read(@file_path),
            headers: default_authenticated_headers.merge('Content-Type' => @mime_type)
        hsh = response_body_hash
        @the_path = hsh['_links']['self']['href']
        @file_id = @the_path.match(%r{/(\d+)$})[1].to_i
      end

      it 'shows the file info for a file that exists (superuser)' do
        response_code = get @the_path, headers: default_authenticated_headers
        expect(response_code).to eq(200)
        hsh = response_body_hash
        expect(hsh['path']).to eq(::File.basename(@file_path))
        expect(hsh['mimeType']).to eq(@mime_type)
        expect(hsh['status']).to eq('created')
      end

      it "doesn't allow listing a file that should be hidden from the public" do
        response_code = get @the_path, headers: default_json_headers
        expect(response_code).to eq(404)
      end

      it 'shows non-public files to the owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get @the_path, headers: default_json_headers.merge(
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
        response_code = get @the_path, headers: default_json_headers.merge(
          'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
        )
        expect(response_code).to eq(200)
      end

      # I added a link to download a file, so testing this
      it 'shows CURIE links to other actions' do
        response_code = get @the_path, headers: default_authenticated_headers
        expect(response_code).to eq(200)
        hsh = response_body_hash
        lnks = hsh['_links']
        # @file_id is set in before
        data_file = StashEngine::DataFile.find(@file_id)
        resource = data_file.resource
        ident_obj = resource.identifier
        # the dataset path is messed up because rails either doesn't encode or double-encodes when you use the helper, so workaround
        ds_path = dataset_path('foobar').gsub('foobar', CGI.escape(ident_obj.to_s))

        expect(lnks['self']['href']).to eq(file_path(@file_id))
        expect(lnks['stash:dataset']['href']).to eq(ds_path)
        expect(lnks['stash:version']['href']).to eq(version_path(resource.id))
        expect(lnks['stash:files']['href']).to eq(version_files_path(resource.id))
        expect(lnks['stash:file-download']['href']).to eq(download_file_path(@file_id))
      end
    end
    # rubocop:enable Security/IoMethods

    describe '#index' do

      before(:each) do
        create_list(:data_file, 25, resource_id: @resources[0].id)
        create_list(:data_file, 4, resource_id: @resources[1].id)
      end

      it 'shows an index of files for a public dataset version' do
        response_code = get "/api/v2/versions/#{@resources[0].id}/files", headers: default_authenticated_headers
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
        response_code = get "/api/v2/versions/#{@resources[1].id}/files", headers: default_authenticated_headers
        hsh = response_body_hash
        expect(response_code).to eq(200)
        expect(hsh['total']).to eq(4)
      end

      it 'shows an index of files for a private dataset version to the owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/versions/#{@resources[1].id}/files", headers: default_json_headers.merge(
          'Authorization' => "Bearer #{access_token}"
        )
        hsh = response_body_hash
        expect(response_code).to eq(200)
        expect(hsh['total']).to eq(4)
      end

      it 'shows an index of files for a private dataset version to the admin' do
        @user.update(role: 'admin', tenant_id: @tenant_ids.first)
        response_code = get "/api/v2/versions/#{@resources[1].id}/files", headers: default_authenticated_headers
        hsh = response_body_hash
        expect(response_code).to eq(200)
        expect(hsh['total']).to eq(4)
      end

      it "doesn't show private version's list of file to non-user" do
        response_code = get "/api/v2/versions/#{@resources[1].id}/files", headers: default_json_headers
        expect(response_code).to eq(404)
      end

      it "doesn't show private versions list of files to a random user" do
        @user.update(role: 'user', tenant_id: @tenant_ids.first)
        response_code = get "/api/v2/versions/#{@resources[1].id}/files", headers: default_authenticated_headers
        expect(response_code).to eq(404)
      end

      it 'shows files from a previously-published version when the files of the given version are invisible' do
        # force @resources[1] to status published, but mark the file_view as false
        @curation_activities << [create(:curation_activity, resource: @resources[1], status: 'curation'),
                                 create(:curation_activity, resource: @resources[1], status: 'published')]
        @resources[1].current_resource_state.update(resource_state: 'submitted')
        @resources[0].update(file_view: true)
        @resources[1].update(file_view: false)
        # retrieve the files
        response_code = get "/api/v2/versions/#{@resources[1].id}/files", headers: default_authenticated_headers
        hsh = response_body_hash
        expect(response_code).to eq(200)
        # check that they are the files from the visible version @resources[0]
        expect(hsh['total']).to eq(25)
      end
    end

    describe '#destroy' do
      before(:each) do
        # make two lists of files for versions that are representative of how stuff works for versioning
        # with second version inheriting the files from the first showing as copied over internally
        @files = [create_list(:data_file, 4, resource_id: @resources[0].id)]
        tmp = @files.first.map(&:amoeba_dup)
        tmp.each do |f|
          f.file_state = 'copied'
          f.resource_id = @resources[1].id
          f.save!
        end
        @files << tmp
      end

      it 'allows destroying file if superuser' do
        response_code = delete "/api/v2/files/#{@files[1].first.id}", headers: default_authenticated_headers
        expect(response_code).to eq(200) # maybe this should be 202 for an item that is marked for deletion when we revise
        hsh = response_body_hash
        expect(hsh['status']).to eq('deleted')
      end

      it 'allows destroying file if owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = delete "/api/v2/files/#{@files[1].first.id}", headers: default_authenticated_headers
          .merge('Authorization' => "Bearer #{access_token}")
        expect(response_code).to eq(200) # maybe this should be 202 for an item that is marked for deletion when we revise
        hsh = response_body_hash
        expect(hsh['status']).to eq('deleted')
      end

      it 'allows destroying file if admin for same tenant' do
        @user.update(role: 'admin', tenant_id: @tenant_ids.first)
        response_code = delete "/api/v2/files/#{@files[1].first.id}", headers: default_authenticated_headers
        expect(response_code).to eq(200)
        hsh = response_body_hash
        expect(hsh['status']).to eq('deleted')
      end

      it 'blocks anonymous users from destroying files' do
        response_code = delete "/api/v2/files/#{@files[1].first.id}", headers: default_json_headers
        expect(response_code).to eq(401)
      end

      it 'blocks destroying file if another regular user' do
        @user.update(role: 'user')
        response_code = delete "/api/v2/files/#{@files[1].first.id}", headers: default_authenticated_headers
        expect(response_code).to eq(401)
      end

      it "blocks destroying file if the version isn't being edited" do
        response_code = delete "/api/v2/files/#{@files[0].first.id}", headers: default_authenticated_headers
        expect(response_code).to eq(403)
      end
    end

    describe 'download' do
      before(:each) do
        # make two lists of files for versions that are representative of how stuff works for versioning
        # with second version inheriting the files from the first showing as copied over internally
        @files = [create_list(:data_file, 4, resource_id: @resources[0].id)]
        tmp = @files.first.map(&:amoeba_dup)
        tmp.each do |f|
          f.file_state = 'copied'
          f.resource_id = @resources[1].id
          f.save!
        end
        @files << tmp

        allow_any_instance_of(Stash::Download::FilePresigned).to receive(:download) do |o|
          # o is the object instance and cc is the controller context
          # o.cc.response.headers['Location'] = 'http://example.com'
          # o.cc.render -- this isn't needed in the tests and causes a double-render which is different than the actual method
          o.cc.redirect_to 'http://example.com'
        end
      end

      it 'allows download by public for published' do
        @resources[0].update(publication_date: Time.new - 24.hours,
                             current_state: 'submitted',
                             file_view: true)
        response_code = get "/api/v2/files/#{@files[0].first.id}/download"
        expect(response_code).to eq(302)
      end

      it 'allows download by superuser for unpublished but in Merritt' do
        @curation_activities[0][2].destroy!
        response_code = get "/api/v2/files/#{@files[0].first.id}/download", headers: default_authenticated_headers.merge('Accept' => '*')
        expect(response_code).to eq(302)
      end

      it 'allows download by owner for unpublished but in Merritt' do
        @curation_activities[0][2].destroy!
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user1.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        response_code = get "/api/v2/files/#{@files[0].first.id}/download", headers: default_json_headers
          .merge('Accept' => '*', 'Authorization' => "Bearer #{access_token}")
        expect(response_code).to eq(302)
      end

      it 'allows download by admin for tenant for unpublished but in Merritt' do
        @curation_activities[0][2].destroy!
        @user.update(role: 'admin', tenant_id: @tenant_ids.first)
        response_code = get "/api/v2/files/#{@files[0].first.id}/download", headers: default_authenticated_headers.merge('Accept' => '*')
        expect(response_code).to eq(302)
      end

      it 'disallows download by anonymous for unpublished' do
        @curation_activities[0][2].destroy!
        response_code = get "/api/v2/files/#{@files[0].first.id}/download", headers: default_json_headers.merge('Accept' => '*')
        expect(response_code).to eq(404)
      end

      it 'disallows download by random normal user for unpublished' do
        @curation_activities[0][2].destroy!
        @user.update(role: 'user', tenant_id: @tenant_ids.first)
        response_code = get "/api/v2/files/#{@files[0].first.id}/download", headers: default_authenticated_headers.merge('Accept' => '*')
        expect(response_code).to eq(404)
      end

      it 'disallows download for an unsubmitted to Merritt version' do
        response_code = get "/api/v2/files/#{@files[1].first.id}/download", headers: default_authenticated_headers.merge('Accept' => '*')
        expect(response_code).to eq(404)
      end
    end
  end
end
# rubocop:enable

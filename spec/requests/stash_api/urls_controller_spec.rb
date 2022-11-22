require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
require 'digest'
# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec

module StashApi

  FILE_HASH = {
    'skipValidation' => true,
    'url' => 'http://github.com/CDL-Dryad/dryad-app/raw/main/app/assets/images/favicon.ico',
    'digestType' => 'md5',
    'path' => 'favicon.ico',
    'mimeType' => 'image/vnd.microsoft.icon',
    'size' => ::File.size(Rails.root.join('spec/fixtures/http_responses/favicon.ico')),
    'digest' => Digest::MD5.hexdigest(::File.read(Rails.root.join('spec/fixtures/http_responses/favicon.ico'))),
    'description' => 'Super fun comment from old Dryad'
  }.freeze

  RSpec.describe UrlsController, type: :request do

    include Mocks::CurationActivity
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::Repository
    include Mocks::Tenant
    include Mocks::UrlUpload

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
      neuter_curation_callbacks!
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

      # be sure versions are set correctly, because creating them manually like this doesn't ensure it
      @resources[0].stash_version.update(version: 1)
      @resources[1].stash_version.update(version: 2)
    end

    # Test creation of new manifest URL by getting basic info from a HEAD request and populating it. Just a basic test.
    # There are workarounds in the URL discovering library for Google drive and doing GET requests and some other stuff,
    # but that really belongs being tested at that component level and probably not here.
    describe '#create' do
      it 'will retrive, validate and fill in info from a URL from the internet by HEAD request' do
        mock_github_head_request!
        test_url = 'http://github.com/CDL-Dryad/dryad-app/raw/main/app/assets/images/favicon.ico'
        response_code = post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
                             params: { url: test_url }.to_json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(201)
        hsh = response_body_hash
        expect(hsh['path']).to eq('favicon.ico')
        expect(hsh['url']).to eq('http://github.com/CDL-Dryad/dryad-app/raw/main/app/assets/images/favicon.ico')
        expect(hsh['size']).to eq(6318)
        expect(hsh['mimeType']).to eq('image/vnd.microsoft.icon')
        expect(hsh['status']).to eq('created')
      end

      it 'will take a manual population of url info without validation.  At your own risk and may barf on Merritt submission' do
        response_code = post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
                             params: FILE_HASH.to_json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(201)
        hsh = response_body_hash
        FILE_HASH.keys.reject { |k| k == 'skipValidation' }.each do |key|
          expect(hsh[key]).to eq(FILE_HASH[key])
        end
      end

      it 'does not allow regular users to populate urls that are not validated' do
        @user.update(role: 'user')
        response_code = post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
                             params: FILE_HASH.to_json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(401)
      end

      it "doesn't allow anonymous (not logged in) users to add urls" do
        mock_github_head_request!
        test_url = 'http://github.com/CDL-Dryad/dryad-app/raw/main/app/assets/images/favicon.ico'
        response_code = post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
                             params: { url: test_url }.to_json,
                             headers: default_json_headers
        expect(response_code).to eq(401)
      end

      it "doesn't allow adding the same URL multiple times" do
        mock_github_head_request!
        test_url = 'http://github.com/CDL-Dryad/dryad-app/raw/main/app/assets/images/favicon.ico'
        post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
             params: { url: test_url }.to_json,
             headers: default_authenticated_headers
        response_code = post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
                             params: { url: test_url }.to_json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(403)
        expect(response_body_hash.key?('error')).to eq(true)
      end

      it 'disallows invalid-format urls' do
        mock_github_head_request!
        test_url = 'groogalona.fun/'
        response_code = post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
                             params: { url: test_url }.to_json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(403)
      end

      it 'gives an error for non-validating urls (404)' do
        mock_github_bad_head_request!
        test_url = 'http://github.com/CDL-Dryad/dryad-app/raw/main/app/assets/images/favicon.ico'
        response_code = post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
                             params: { url: test_url }.to_json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(403)
        expect(response_body_hash.key?('error')).to eq(true)
      end

      it "doesn't allow updates without an in-progress version (Merritt-status)" do
        @resources[0].current_resource_state.update(resource_state: 'submitted')
        @resources[1].current_resource_state.update(resource_state: 'processing')
        mock_github_head_request!
        test_url = 'http://github.com/CDL-Dryad/dryad-app/raw/main/app/assets/images/favicon.ico'
        response_code = post "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}/urls",
                             params: { url: test_url }.to_json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(403)
        expect(response_body_hash.key?('error')).to eq(true)
      end
    end
  end
end
# rubocop:enable

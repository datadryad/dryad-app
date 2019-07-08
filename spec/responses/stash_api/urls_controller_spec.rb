require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
require 'digest'

# rubocop:disable Metrics/BlockLength
# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe UrlsController, type: :request do

    include Mocks::Ror
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::CurationActivity
    include Mocks::Repository
    include Mocks::UrlUpload

    before(:all) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)

      FILE_HASH = {
        'skipValidation' => true,
        'url' => 'http://github.com/CDL-Dryad/dryad/raw/master/app/assets/images/favicon.ico',
        'digestType' => 'md5',
        'path' => 'favicon.ico',
        'mimeType' => 'image/vnd.microsoft.icon',
        'size' => ::File.size(Rails.root.join('spec/fixtures/http_responses/favicon.ico')),
        'digest' => Digest::MD5.hexdigest(::File.read(Rails.root.join('spec/fixtures/http_responses/favicon.ico'))),
        'description' => 'Super fun comment from old Dryad'
      }.freeze
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

      @curation_activities << [create(:curation_activity, resource: @resources[1], status: 'in_progress')]

      # be sure versions are set correctly, because creating them manually like this doesn't ensure it
      @resources[0].stash_version.update(version: 1)
      @resources[1].stash_version.update(version: 2)
    end

    # Test creation of new manifest URL by getting basic info from a HEAD request and populating it. Just a basic test.
    # There are workarounds in the URL discovering library for Google drive and doing GET requests and some other stuff,
    # but that really belongs being tested at that component level and probably not here.
    describe '#index' do
      it 'will retrive, validate and fill in info from a URL from the internet by HEAD request' do
        mock_github_head_request!
        test_url = 'http://github.com/CDL-Dryad/dryad/raw/master/app/assets/images/favicon.ico'
        response_code = post "/api/datasets/#{CGI.escape(@identifier.to_s)}/urls", { url: test_url }.to_json, default_authenticated_headers
        expect(response_code).to eq(201)
        hsh = response_body_hash
        expect(hsh['path']).to eq('favicon.ico')
        expect(hsh['url']).to eq('http://github.com/CDL-Dryad/dryad/raw/master/app/assets/images/favicon.ico')
        expect(hsh['size']).to eq(6318)
        expect(hsh['mimeType']).to eq('image/vnd.microsoft.icon')
        expect(hsh['status']).to eq('created')
      end

      it 'will take a manual population of url info without validation.  At your own risk and may barf on Merritt submission' do
        response_code = post "/api/datasets/#{CGI.escape(@identifier.to_s)}/urls", FILE_HASH.to_json, default_authenticated_headers
        expect(response_code).to eq(201)
        hsh = response_body_hash
        FILE_HASH.keys.reject { |k| k == 'skipValidation' }.each do |key|
          expect(hsh[key]).to eq(FILE_HASH[key])
        end
      end


    end

  end
end
# rubocop:enable Metrics/BlockLength

require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe RelatedWorksController, type: :request do

    include Mocks::CurationActivity
    include Mocks::Salesforce
    include Mocks::Tenant

    # there is all kinds of confusion and badness creating urls with DOIs using route helpers since they have slashes
    # in them and not as path separators in the URL. This makes them be properly escaped.
    def related_url(dataset_doi:, related_doi:)
      "/api/v2/datasets/#{CGI.escape(dataset_doi)}/related_works/#{CGI.escape(related_doi)}"
    end

    before(:each) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)

      neuter_curation_callbacks!
      mock_tenant!

      @tenant_ids = StashEngine::Tenant.all.map(&:tenant_id)

      @user1 = create(:user, tenant_id: @tenant_ids.first, role: 'user')

      @identifier = create(:identifier)
      @resource = create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifier.id)
    end

    describe '#update' do

      it 'gives error if dataset doi does not exist' do
        @path = related_url(dataset_doi: 'bad_doi', related_doi: 'doi:10.1184/6478826')

        response_code = put @path,
                            params: { work_type: 'article' }.to_json, # same as report2 json
                            headers: default_authenticated_headers

        expect(response_code).to eq(404)
        expect(response_body_hash['error']).to include('not-found')
      end

      it 'gives error if related doi is not formatted correctly' do
        @path = related_url(dataset_doi: @identifier.to_s, related_doi: 'bad_doi')

        response_code = put @path,
                            params: { work_type: 'article' }.to_json, # same as report2 json
                            headers: default_authenticated_headers

        expect(response_code).to eq(400)
        expect(response_body_hash['error']).to include("related DOI isn't formatted correctly")
      end

      it 'gives error if work type is incorrect' do
        @path = related_url(dataset_doi: @identifier.to_s, related_doi: 'doi:10.1184/6478826')

        response_code = put @path,
                            params: { work_type: 'catfood' }.to_json, # same as report2 json
                            headers: default_authenticated_headers

        expect(response_code).to eq(400)
        expect(response_body_hash['error']).to include('work_type is invalid')
      end

      it 'updates the related work for the dataset' do
        @path = related_url(dataset_doi: @identifier.to_s, related_doi: 'doi:10.1184/6478826')

        response_code = put @path,
                            params: { work_type: 'article' }.to_json, # same as report2 json
                            headers: default_authenticated_headers

        expect(response_code).to eq(200)
        expect(response_body_hash).to eq({ 'relationship' => 'article', 'identifierType' => 'DOI',
                                           'identifier' => 'https://doi.org/10.1184/6478826' })
      end

      it 'updates the curation activity to indicate update' do
        @path = related_url(dataset_doi: @identifier.to_s, related_doi: 'doi:10.1184/6478826')

        response_code = put @path,
                            params: { work_type: 'article' }.to_json, # same as report2 json
                            headers: default_authenticated_headers

        expect(response_code).to eq(200)
        last_cur = @resource.reload.last_curation_activity
        expect(last_cur.note).to start_with('Related article added')
        expect(last_cur.status).to eq(@resource.curation_activities.first.status)
      end

      it 'sends an email for this update' do
        ActionMailer::Base.delivery_method = :smtp
        @path = related_url(dataset_doi: @identifier.to_s, related_doi: 'doi:10.1184/6478826')

        expect do
          put @path,
              params: { work_type: 'article' }.to_json, # same as report2 json
              headers: default_authenticated_headers
        end.to raise_error(Errno::ECONNREFUSED)

        ActionMailer::Base.delivery_method = :test
      end
    end
  end
end

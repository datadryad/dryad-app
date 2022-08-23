require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe FrictionlessReportsController, type: :request do

    include Mocks::CurationActivity
    include Mocks::Repository
    include Mocks::Tenant

    # set up some versions with different curation statuses (visibility)
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

      create(:curation_activity, resource: @resource, status: 'in_progress')

      @resource.current_resource_state.update(resource_state: 'in_progress')
      # be sure versions are set correctly, because creating them manually like this doesn't ensure it
      @resource.stash_version.update(version: 1)
      @generic_file = create(:generic_file, resource: @resource)
    end

    describe '#show' do
      before(:each) do
        @frict_report = create(:frictionless_report, generic_file: @generic_file)
        @path = Rails.application.routes.url_helpers.file_frictionless_report_path(@generic_file.id)
      end

      it 'shows the frictionless report info for a file that exists and has report (superuser)' do
        response_code = get @path, headers: default_authenticated_headers
        expect(response_code).to eq(200)
        hsh = response_body_hash
        expect(hsh['_links']['self']['href']).to eq(@path)
        expect(hsh['status']).to eq(@frict_report.status)
        expect(hsh['report']).to eq(@frict_report.report)
      end

      it "doesn't show a report for an item the user doesn't have permission for" do
        @user.update(role: 'user')
        response_code = get @path, headers: default_authenticated_headers
        expect(response_code).to eq(404)
        expect(response_body_hash).to eq({"error"=>"not-found"})
      end

    end

  end
end

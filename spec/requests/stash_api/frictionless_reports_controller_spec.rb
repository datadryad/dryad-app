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
        expect(response_body_hash).to eq({ 'error' => 'not-found' })
      end

      it "returns 404 if report doesn't exist" do
        @frict_report.destroy!
        response_code = get @path, headers: default_authenticated_headers
        expect(response_code).to eq(404)
      end
    end

    describe '#update' do
      before(:each) do
        @generic_file2 = create(:generic_file, resource: @resource)
        @frict_report2 = create(:frictionless_report, generic_file: @generic_file2)
        @path = Rails.application.routes.url_helpers.file_frictionless_report_path(@generic_file.id)
      end

      it "adds a report that doesn't exist yet" do
        response_code = put @path,
                            params: { status: 'noissues', report: @frict_report2.report }.to_json, # same as report2 json
                            headers: default_authenticated_headers
        expect(response_code).to eq(200)
        hsh = response_body_hash
        expect(hsh['status']).to eq('noissues')
        expect(hsh['report']).to eq(@frict_report2.report)
      end

      it 'updates a report that does exist' do
        @frict_report = create(:frictionless_report, generic_file: @generic_file)
        report_id = @frict_report.id
        response_code = put @path,
                            params: { status: 'noissues', report: @frict_report2.report }.to_json, # same as report2 json
                            headers: default_authenticated_headers
        expect(response_code).to eq(200)
        hsh = response_body_hash
        expect(hsh['status']).to eq('noissues')
        expect(hsh['report']).to eq(@frict_report2.report)
        expect(StashEngine::FrictionlessReport.find(report_id).report).to eq(@frict_report2.report) # the id is the same
      end

      it "doesn't allow updating without the correct permissions" do
        @user.update(role: 'user')
        response_code = put @path,
                            params: { status: 'noissues', report: @frict_report2.report }.to_json, # same as report2 json
                            headers: default_authenticated_headers
        expect(response_code).to eq(401)
        hsh = response_body_hash
        expect(hsh['error']).to eq('unauthorized')
      end

      it "doesn't allow updating unless logged in" do
        response_code = put @path,
                            params: { status: 'noissues', report: @frict_report2.report }.to_json, # same as report2 json
                            headers: default_json_headers
        expect(response_code).to eq(401)
      end

      it "doesn't allow updating unless a status is correct from the list" do
        response_code = put @path,
                            params: { status: 'squid_cats', report: @frict_report2.report }.to_json,
                            headers: default_authenticated_headers
        expect(response_code).to eq(400)
        hsh = response_body_hash
        expect(hsh['error']).to eq('incorrect status set')
      end
    end
  end
end

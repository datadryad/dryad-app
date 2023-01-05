require 'uri'
require_relative 'helpers'

module StashApi
  RSpec.describe ProcessorResultsController, type: :request do

    before(:all) do
      host! 'my.example.org'
      @user = create(:user, role: 'superuser')

      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                       owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
      @tenant_ids = StashEngine::Tenant.all.map(&:tenant_id)
    end

    after(:all) do
      @user.destroy
      @doorkeeper_application.destroy
    end

    before(:each) do
      @resource = create(:resource)
      @file = create(:data_file, resource: @resource)
      @processor_result = create(:processor_result, resource: @resource, parent_id: @file.id)
    end

    describe :show do
      it 'retrieves information about the processing result' do
        response_code = get "/api/v2/processor_results/#{@processor_result.id}", headers: default_authenticated_headers
        expect(response_code).to eq(200)
        h = response_body_hash
        expect(h['id']).to eq(@processor_result.id)
        expect(h['resource_id']).to eq(@processor_result.resource_id)
        expect(h['processing_type']).to eq(@processor_result.processing_type)
        expect(h['parent_id']).to eq(@processor_result.parent_id)
        expect(h['completion_state']).to eq(@processor_result.completion_state)
        expect(h['message']).to eq(@processor_result.message)
        expect(h['structured_info']).to eq(@processor_result.structured_info)
      end

      it 'gives rejection if public user that cannot view' do
        response_code = get "/api/v2/processor_results/#{@processor_result.id}", headers: default_json_headers
        expect(response_code). to eq(401)
      end
    end

  end
end

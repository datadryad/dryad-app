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

    describe :update do
      it 'updates the information about an existing processing result' do
        @processor_result2 = create(:processor_result, resource: @resource, parent_id: 1234, processing_type: 'compressed_info',
                                                       completion_state: 'error')
        response_code = put "/api/v2/processor_results/#{@processor_result.id}",
                            params: @processor_result2.to_json, # has more than required keys, extras will be ignored
                            headers: default_authenticated_headers

        expect(response_code).to eq(200)
        h = response_body_hash

        expect(h['id']).to eq(@processor_result.id)
        expect(h['resource_id']).to eq(@processor_result.resource_id)
        expect(h['processing_type']).to eq(@processor_result2.processing_type)
        expect(h['parent_id']).to eq(@processor_result2.parent_id)
        expect(h['completion_state']).to eq(@processor_result2.completion_state)
        expect(h['message']).to eq(@processor_result2.message)
        expect(h['structured_info']).to eq(@processor_result2.structured_info)
      end
    end

    describe :index do
      it 'shows an index of processors that have run for the resource' do
        @processor_result2 = create(:processor_result, resource: @resource, parent_id: @file.id)
        response_code = get "/api/v2/versions/#{@resource.id}/processor_results",
                            headers: default_authenticated_headers

        expect(response_code).to eq(200)
        r = response_body_hash
        expect(r.length).to eq(2)
        expect(r.first['message']).to eq(@processor_result.message)
        expect(r.second['message']).to eq(@processor_result2.message)
      end
    end

    describe :create do
      it 'creates a new processor result' do
        # just creating a factory object so I can copy data for a new item, it's not saved with build
        pr = build(:processor_result)
        data = { processing_type: pr.processing_type, parent_id: @file.id,
                 completion_state: pr.completion_state, message: pr.message, structured_info: pr.structured_info }

        response_code = post "/api/v2/versions/#{@resource.id}/processor_results",
                             params: data.to_json,
                             headers: default_authenticated_headers

        expect(response_code).to eq(200)

        h = response_body_hash
        expect(h['resource_id']).to eq(@resource.id)
        expect(h['processing_type']).to eq(pr.processing_type)
        expect(h['parent_id']).to eq(@file.id)
        expect(h['completion_state']).to eq(pr.completion_state)
        expect(h['message']).to eq(pr.message)
        expect(h['structured_info']).to eq(pr.structured_info)
        expect(h['id']).not_to eq(@processor_result.id) # this is a new one
      end
    end

  end
end

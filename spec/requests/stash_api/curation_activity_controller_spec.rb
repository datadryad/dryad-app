require 'rails_helper'
require_relative 'helpers'

module StashApi
  RSpec.describe CurationActivityController, type: :request do
    include Mocks::Salesforce

    let!(:user) { create(:user, role: 'superuser') }
    let!(:system_user) { create(:user, id: 0, first_name: 'Dryad', last_name: 'System') }
    let!(:doorkeeper_application) do
      create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', owner_id: user.id, owner_type: 'StashEngine::User')
    end

    let(:identifier) { create(:identifier) }
    let!(:resource) { create(:resource, identifier: identifier, created_at: 2.minutes.ago) }
    let(:dataset_id) { CGI.escape(identifier.to_s) }
    let(:submit_ca) { create(:curation_activity, resource: resource, note: 'Activity 1', status: 'queued', user: user) }
    let(:curation_ca) { create(:curation_activity, resource: resource, note: 'Activity 2', status: 'curation') }

    before do
      mock_salesforce!
      setup_access_token(doorkeeper_application: doorkeeper_application)
    end

    describe '#index' do
      before do
        sleep(0.5)
        submit_ca
        sleep(0.5)
        curation_ca
        get "/api/v2/datasets/#{dataset_id}/curation_activity", headers: default_authenticated_headers
      end

      it 'returns proper activities' do
        expect(response).to have_http_status(:ok)
        output = response_body_hash

        expect(output.size).to eq(3)
        expect(output.map { |a| a['status'] }).to contain_exactly('In progress', 'Queued for curation', 'Curation')
        expect(output.map { |a| a['note'] }).to contain_exactly(nil, 'Activity 1', 'Activity 2')
      end
    end

    describe '#show' do
      context 'with existing activity' do
        it 'returns activity_details' do
          get "/api/v2/datasets/#{dataset_id}/curation_activity/#{submit_ca.id}", headers: default_authenticated_headers
          expect(response).to have_http_status(:ok)
          output = response_body_hash

          expect(output[:id]).to eq(submit_ca.id)
          expect(output[:action_taken_by]).to eq(user.name)
          expect(output[:dataset]).to eq(identifier.to_s)
          expect(output[:keywords]).to eq(nil)
          expect(output[:note]).to eq('Activity 1')
          expect(output[:status]).to eq('Queued for curation')
        end
      end

      context 'with missing activity' do
        it 'returns 404' do
          get "/api/v2/datasets/#{dataset_id}/curation_activity/12345321", headers: default_authenticated_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe '#create' do
      before do
        allow(CostReportingService).to receive_message_chain(:new, :notify_partner_of_large_data_submission).and_return(true)
      end

      it 'created and returns the new activity' do
        curation_activity_attrs = {
          curation_activity: {
            note: 'New activity note',
            status: 'queued'
          }
        }
        expect do
          post "/api/v2/datasets/#{dataset_id}/curation_activity", params: curation_activity_attrs.to_json, headers: default_authenticated_headers
        end.to change(StashEngine::CurationActivity, :count).by(1)

        expect(response).to have_http_status(:ok)
        output = response_body_hash
        expect(output[:status]).to eq('Queued for curation')
        expect(output[:note]).to eq('New activity note')
      end
    end

    describe '#update' do
      before { submit_ca }

      it 'updates and returns the new activity' do
        curation_activity_attrs = {
          curation_activity: {
            note: 'New activity note',
            status: 'queued'
          }
        }

        expect do
          put "/api/v2/datasets/#{dataset_id}/curation_activity/#{submit_ca.id}", params: curation_activity_attrs.to_json,
                                                                                  headers: default_authenticated_headers
        end.to change(StashEngine::CurationActivity, :count).by(1)

        expect(response).to have_http_status(:ok)
        output = response_body_hash
        expect(output[:status]).to eq('Queued for curation')
        expect(output[:note]).to eq('New activity note')
      end
    end

    describe '#destroy' do
      before { submit_ca }

      context 'with existing activity' do
        it 'deleted the curation activity' do
          expect do
            delete "/api/v2/datasets/#{dataset_id}/curation_activity/#{submit_ca.id}", headers: default_authenticated_headers
          end.to change(StashEngine::CurationActivity, :count).by(-1)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with missing activity' do
        it 'returns 404' do
          delete "/api/v2/datasets/#{dataset_id}/curation_activity/12345321", headers: default_authenticated_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end

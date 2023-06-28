require 'rails_helper'
require 'uri'
require_relative '../stash_api/helpers'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashDatacite
  RSpec.describe AffiliationsController, type: :request do

    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!
      @user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )

      @resource = create(:resource, user_id: @user.id)
      allow_any_instance_of(ContributorsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

      stub_request(:get, 'https://api.crossref.org/funders?query=sorbonne%20universit%C3%A9')
        .with(
          headers: {
            'Connection' => 'close',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: File.open(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'fundref_response1.json')),
                   headers: { 'content-type' => 'application/json' })

      stub_request(:get, 'https://api.crossref.org/funders?query=crap')
        .with(
          headers: {
            'Connection' => 'close',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: File.open(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'fundref_response1.json')),
                   headers: { 'content-type' => 'application/json' })
    end

    describe 'create' do
      before(:each) do

        @params_hash = { 'utf8' => '✓', 'contributor' =>
          { 'contributor_name' => 'Sorbonne Université',
            'name_identifier_id' => '', 'award_number' => '',
            'contributor_type' => 'funder',
            'identifier_type' => 'crossref_funder_id',
            'resource_id' => @resource.id, 'id' => '' } }
      end

      it 'saves an exact match for a funder with the crossref funder id' do
        @resource.contributors = [] # erase the default funder
        post '/stash_datacite/contributors/create', params: @params_hash, xhr: true
        contrib = StashDatacite::Contributor.where(resource_id: @resource.id).first
        expect(contrib.contributor_name).to eq('Sorbonne Université')
        expect(contrib.identifier_type).to eq('crossref_funder_id')
        expect(contrib.name_identifier_id).to eq('http://dx.doi.org/10.13039/501100019125')
      end

      it "doesn't save an identifier and puts an asterisk if that one doesn't match up" do
        @resource.contributors = [] # erase the default funder
        @params_hash['contributor']['contributor_name'] = 'crap'
        post '/stash_datacite/contributors/create', params: @params_hash, xhr: true
        contrib = StashDatacite::Contributor.where(resource_id: @resource.id).first
        expect(contrib.contributor_name).to eq('crap*')
        expect(contrib.name_identifier_id).to eq('')
      end
    end

    describe 'reorder' do
      before(:each) do
        @resource2 = create(:resource, user_id: @user.id)
        @contributors = Array.new(7) { |_i| create(:contributor, resource: @resource2) }
      end

      it 'detects if not all funder ids are for same resource' do
        @bad_funder = create(:contributor, resource: @resource)
        update_info = (@contributors + [@bad_funder]).to_h { |funder| [funder.id.to_s, funder.funder_order] }

        response_code = patch '/stash_datacite/contributors/reorder',
                              params: { 'contributor' => update_info },
                              headers: default_json_headers,
                              as: :json

        expect(response_code).to eq(400) # gives 400, bad request
      end

      it 'detects if user not authorized to modify this resource' do
        @user2 = create(:user, role: 'user')
        @resource3 = create(:resource, user_id: @user2.id)
        @contributors2 = Array.new(7) { |_i| create(:contributor, resource: @resource3) }
        update_info = @contributors2.to_h { |funder| [funder.id.to_s, funder.funder_order] }

        response_code = patch '/stash_datacite/contributors/reorder',
                              params: { 'contributor' => update_info },
                              headers: default_json_headers,
                              as: :json

        expect(response_code).to eq(403) # no permission to modify these
      end

      it 'updates the funder order to the order given' do
        update_info = @contributors.map { |funder| { id: funder.id, order: funder.funder_order } }.shuffle
        update_info = update_info.each_with_index.to_h do |funder, idx|
          [funder[:id].to_s, idx]
        end

        response_code = patch '/stash_datacite/contributors/reorder',
                              params: { 'contributor' => update_info },
                              headers: default_json_headers,
                              as: :json

        expect(response_code).to eq(200)

        ret_json = JSON.parse(body)

        update_info.each_with_index do |item, idx|
          expect(item.first.to_i).to eq(ret_json[idx]['id'])
          expect(item.second).to eq(ret_json[idx]['funder_order'])
        end
      end
    end

  end
end

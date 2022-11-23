require 'rails_helper'
require 'uri'

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

  end
end

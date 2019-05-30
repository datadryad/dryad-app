require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
# rubocop:disable Metrics/BlockLength, Metrics/ModuleLength
module StashApi
  RSpec.describe DatasetsController, type: :request do

    include Mocks::Ror
    include Mocks::RSolr
    include Mocks::Stripe

    before(:all) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    # test creation of a new dataset
    describe '#create' do
      before(:each) do
        mock_ror!
        mock_solr!
        mock_stripe!
        @meta = Fixtures::StashApi::Metadata.new
        @meta.make_minimal
      end

      it 'creates a new dataset from minimal metadata (title, author info, abstract)' do
        # the following works for post with headers
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        output = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(201)
        expect(%r{doi:10.5072/dryad\..{8}}).to match(output[:identifier])
        hsh = @meta.hash
        expect(hsh[:title]).to eq(output[:title])
        expect(hsh[:abstract]).to eq(output[:abstract])
        in_author = hsh[:authors].first
        out_author = output[:authors].first
        expect(in_author).to eq(out_author)
      end

      it 'creates a new basic dataset with a placename' do
        @meta.add_place
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        output = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(201)

        # check it against the database
        @stash_id = StashEngine::Identifier.find(output[:id])
        @resource = @stash_id.resources.first
        expect(@resource.geolocations.first.geolocation_place.geo_location_place).to eq(@meta.hash[:locations].first[:place])

        # check it against the return json
        expect(output[:locations].first[:place]).to eq(@meta.hash[:locations].first[:place])
      end

      it 'creates a new curation activity and sets the publication date' do
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        output = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(201)
        @stash_id = StashEngine::Identifier.find(output[:id])
        @resource = @stash_id.resources.last
        expect(@resource.curation_activities.size).to eq(1)

        @curation_activity = Fixtures::StashApi::CurationMetadata.new
        dataset_id = CGI.escape(output[:identifier])
        response_code = post "/api/datasets/#{dataset_id}/curation_activity", @curation_activity.json, default_authenticated_headers
        expect(response_code).to eq(200)

        @resource.reload
        expect(@resource.curation_activities.size).to eq(2)
        expect(@resource.publication_date).to be
      end

      it 'does not update the publication date if one is already set' do
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        output = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(201)
        @stash_id = StashEngine::Identifier.find(output[:id])
        @resource = @stash_id.resources.last
        expect(@resource.curation_activities.size).to eq(1)

        # Set a publication date in the past
        publish_date = Time.now - 10.days
        @resource.update!(publication_date: publish_date)

        @curation_activity = Fixtures::StashApi::CurationMetadata.new
        dataset_id = CGI.escape(output[:identifier])
        response_code = post "/api/datasets/#{dataset_id}/curation_activity", @curation_activity.json, default_authenticated_headers
        expect(response_code).to eq(200)

        @resource.reload
        expect(@resource.curation_activities.size).to eq(2)
        expect(@resource.publication_date).to be_within(10.seconds).of(publish_date)
      end
    end

    describe '#index' do

      before(:each) do
        mock_ror!
        # these tests are very similar to tests in the model controller for identifier for querying this scope
        @user1 = create(:user, tenant_id: 'ucop', role: nil)
        @user2 = create(:user, tenant_id: 'ucop', role: 'admin')
        @user3 = create(:user, tenant_id: 'ucb', role: 'superuser')

        @identifiers = []
        0.upto(7).each { |_i| @identifiers.push(create(:identifier)) }

        @resources = [create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifiers[0].id),
                      create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifiers[0].id),
                      create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifiers[1].id),
                      create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[2].id),
                      create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[2].id),
                      create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[3].id),
                      create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[4].id),
                      create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[5].id),
                      create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[6].id),
                      create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[7].id)]

        @curation_activities = [[create(:curation_activity_no_callbacks, resource: @resources[0], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[0], status: 'curation'),
                                 create(:curation_activity_no_callbacks, resource: @resources[0], status: 'published')]]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[1], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[1], status: 'curation'),
                                 create(:curation_activity_no_callbacks, resource: @resources[1], status: 'embargoed')]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[2], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[2], status: 'curation')]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[3], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[3], status: 'curation'),
                                 create(:curation_activity_no_callbacks, resource: @resources[3], status: 'action_required')]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[4], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[4], status: 'curation'),
                                 create(:curation_activity_no_callbacks, resource: @resources[4], status: 'published')]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[5], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[5], status: 'curation'),
                                 create(:curation_activity_no_callbacks, resource: @resources[5], status: 'embargoed')]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[6], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[6], status: 'curation'),
                                 create(:curation_activity_no_callbacks, resource: @resources[6], status: 'withdrawn')]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[7], status: 'in_progress')]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[8], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[8], status: 'curation'),
                                 create(:curation_activity_no_callbacks, resource: @resources[8], status: 'published')]

        @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[9], status: 'in_progress'),
                                 create(:curation_activity_no_callbacks, resource: @resources[9], status: 'curation'),
                                 create(:curation_activity_no_callbacks, resource: @resources[9], status: 'embargoed')]

        # 5 public datasets
        #
      end

      describe 'user and role permitted scope' do
        it 'gets a list of public datasets (public status is known by curation status)' do
          get '/api/datasets', {}, default_json_headers
          output = JSON.parse(response.body).with_indifferent_access
          expect(output[:count]).to eq(5)
        end

        it 'gets a list of all datasets because superusers are omniscient' do
          get '/api/datasets', {}, default_authenticated_headers
          output = JSON.parse(response.body).with_indifferent_access
          expect(output[:count]).to eq(@identifiers.count)
        end

        it 'gets a list for admins: public items and private items in their own library roost' do
          @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                    owner_id: @user2.id, owner_type: 'StashEngine::User')
          setup_access_token(doorkeeper_application: @doorkeeper_application)
          get '/api/datasets', {}, default_authenticated_headers
          output = JSON.parse(response.body).with_indifferent_access
          expect(output[:count]).to eq(6)
          dois = output['_embedded']['stash:datasets'].map { |ds| ds['identifier'] }
          expect(dois).to include(@identifiers[1].to_s) # this would be private otherwise based on curation status
        end

        it 'gets a list for an individual user for public and his own' do
          @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                    owner_id: @user1.id, owner_type: 'StashEngine::User')
          setup_access_token(doorkeeper_application: @doorkeeper_application)
          get '/api/datasets', {}, default_authenticated_headers
          output = JSON.parse(response.body).with_indifferent_access
          expect(output[:count]).to eq(6)
          dois = output['_embedded']['stash:datasets'].map { |ds| ds['identifier'] }
          expect(dois).to include(@identifiers[1].to_s) # this would be private otherwise based on curation status
        end
      end

      describe 'filtering and reduced scoping of list for Dryad special filters' do
        it 'reduces scope to a curation status' do
          get '/api/datasets', { 'curationStatus' => 'curation' }, default_authenticated_headers
          output = JSON.parse(response.body).with_indifferent_access
          expect(output[:count]).to eq(1)
          expect(output['_embedded']['stash:datasets'].first['identifier']).to eq(@identifiers[1].to_s)
        end

        it 'reduces scope to a publisher ISSN' do
          internal_datum = create(:internal_datum, identifier_id: @identifiers[5].id, data_type: 'publicationISSN')
          get '/api/datasets', { 'publicationISSN' => internal_datum.value }, default_authenticated_headers
          output = JSON.parse(response.body).with_indifferent_access
          expect(output[:count]).to eq(1)
          expect(output['_embedded']['stash:datasets'].first['identifier']).to eq(@identifiers[5].to_s)
        end

      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/ModuleLength

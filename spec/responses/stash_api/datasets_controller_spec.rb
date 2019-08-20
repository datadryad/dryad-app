require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
# rubocop:disable Metrics/BlockLength, Metrics/ModuleLength
module StashApi
  RSpec.describe DatasetsController, type: :request do

    include Mocks::Ror
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::CurationActivity
    include Mocks::Repository

    before(:all) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    # test creation of a new dataset
    describe '#create' do
      before(:each) do
        neuter_curation_callbacks!
        mock_ror!
        @meta = Fixtures::StashApi::Metadata.new
        @meta.make_minimal
      end

      it 'creates a new dataset from minimal metadata (title, author info, abstract)' do
        # the following works for post with headers
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        output = response_body_hash
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
        output = response_body_hash
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
        output = response_body_hash
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
        output = response_body_hash
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
        expect(@resource.publication_date).to be_within(10.days).of(publish_date)
      end
    end

    # list of datasets
    describe '#index' do
      before(:each) do
        mock_ror!
        neuter_curation_callbacks!
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

        @curation_activities = [[create(:curation_activity, resource: @resources[0], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[0], status: 'curation'),
                                 create(:curation_activity, resource: @resources[0], status: 'published')]]

        @curation_activities << [create(:curation_activity, resource: @resources[1], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[1], status: 'curation'),
                                 create(:curation_activity, resource: @resources[1], status: 'embargoed')]

        @curation_activities << [create(:curation_activity, resource: @resources[2], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[2], status: 'curation')]

        @curation_activities << [create(:curation_activity, resource: @resources[3], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[3], status: 'curation'),
                                 create(:curation_activity, resource: @resources[3], status: 'action_required')]

        @curation_activities << [create(:curation_activity, resource: @resources[4], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[4], status: 'curation'),
                                 create(:curation_activity, resource: @resources[4], status: 'published')]

        @curation_activities << [create(:curation_activity, resource: @resources[5], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[5], status: 'curation'),
                                 create(:curation_activity, resource: @resources[5], status: 'embargoed')]

        @curation_activities << [create(:curation_activity, resource: @resources[6], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[6], status: 'curation'),
                                 create(:curation_activity, resource: @resources[6], status: 'withdrawn')]

        @curation_activities << [create(:curation_activity, resource: @resources[7], status: 'in_progress')]

        @curation_activities << [create(:curation_activity, resource: @resources[8], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[8], status: 'curation'),
                                 create(:curation_activity, resource: @resources[8], status: 'published')]

        @curation_activities << [create(:curation_activity, resource: @resources[9], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[9], status: 'curation'),
                                 create(:curation_activity, resource: @resources[9], status: 'embargoed')]

        # 5 public datasets
        #
      end

      describe 'user and role permitted scope' do
        it 'gets a list of public datasets (public status is known by curation status)' do
          get '/api/datasets', {}, default_json_headers
          output = response_body_hash
          expect(output[:count]).to eq(5)
        end

        it 'gets a list of all datasets because superusers are omniscient' do
          get '/api/datasets', {}, default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(@identifiers.count)
        end

        it 'gets a list for admins: public items and private items in their own library roost' do
          @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                    owner_id: @user2.id, owner_type: 'StashEngine::User')
          setup_access_token(doorkeeper_application: @doorkeeper_application)
          get '/api/datasets', {}, default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(6)
          dois = output['_embedded']['stash:datasets'].map { |ds| ds['identifier'] }
          expect(dois).to include(@identifiers[1].to_s) # this would be private otherwise based on curation status
        end

        it 'gets a list for an individual user for public and his own' do
          @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                    owner_id: @user1.id, owner_type: 'StashEngine::User')
          setup_access_token(doorkeeper_application: @doorkeeper_application)
          get '/api/datasets', {}, default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(6)
          dois = output['_embedded']['stash:datasets'].map { |ds| ds['identifier'] }
          expect(dois).to include(@identifiers[1].to_s) # this would be private otherwise based on curation status
        end
      end

      describe 'shows appropriate latest resource metadata under identifier based on user' do
        before(:each) do
          # make identifier[0] have a second version that isn't publicly viewable yet
          @curation_activities[1][2].destroy
          # versions not getting set correctly for these two resources for some reason
          @resources[0].stash_version.update(version: 1)
          @resources[1].stash_version.update(version: 2)
        end

        it 'shows the first, published version for a public dataset by default' do
          get '/api/datasets', {}, default_json_headers
          hsh = response_body_hash

          # the first identifier
          expect(hsh['_embedded']['stash:datasets'][0]['identifier']).to eq(@identifiers[0].to_s)

          expect(hsh['_embedded']['stash:datasets'][0]['title']).to eq(@resources[0].title)

          # the first version
          expect(hsh['_embedded']['stash:datasets'][0]['versionNumber']).to eq(1)
        end

        it 'shows the 2nd, unpublished version to superusers who see everything by default' do

          get '/api/datasets', {}, default_authenticated_headers
          hsh = response_body_hash

          # the first identifier
          expect(hsh['_embedded']['stash:datasets'][0]['identifier']).to eq(@identifiers[0].to_s)

          # the second version title
          expect(hsh['_embedded']['stash:datasets'][0]['title']).to eq(@resources[1].title)

          # the second version
          expect(hsh['_embedded']['stash:datasets'][0]['versionNumber']).to eq(2)
        end
      end

      describe 'filtering and reduced scoping of list for Dryad special filters' do
        it 'reduces scope to a curation status' do
          get '/api/datasets', { 'curationStatus' => 'curation' }, default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(1)
          expect(output['_embedded']['stash:datasets'].first['identifier']).to eq(@identifiers[1].to_s)
        end

        it 'reduces scope to a publisher ISSN' do
          internal_datum = create(:internal_datum, identifier_id: @identifiers[5].id, data_type: 'publicationISSN')
          get '/api/datasets', { 'publicationISSN' => internal_datum.value }, default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(1)
          expect(output['_embedded']['stash:datasets'].first['identifier']).to eq(@identifiers[5].to_s)
        end

      end
    end

    # view single dataset
    describe '#show' do
      before(:each) do
        mock_ror!
        neuter_curation_callbacks!

        @tenant_ids = StashEngine::Tenant.all.map(&:tenant_id)

        # I think @user is created for use with doorkeeper already
        @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'user')

        @identifier = create(:identifier)

        @resources = [create(:resource, user_id: @user2.id, tenant_id: @user.tenant_id, identifier_id: @identifier.id),
                      create(:resource, user_id: @user2.id, tenant_id: @user.tenant_id, identifier_id: @identifier.id)]

        @curation_activities = [[create(:curation_activity, resource: @resources[0], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[0], status: 'curation'),
                                 create(:curation_activity, resource: @resources[0], status: 'published')]]

        @curation_activities << [create(:curation_activity, resource: @resources[1], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[1], status: 'curation')]

        # set versions correctly seems not correctly working unless created another way.
        @resources[0].stash_version.update(version: 1)
        @resources[1].stash_version.update(version: 2)
      end

      it 'shows a public record for a created indentifier/resource' do
        get "/api/datasets/#{CGI.escape(@identifier.to_s)}", {}, default_json_headers # not logged in
        hsh = response_body_hash
        expect(hsh['versionNumber']).to eq(1)
        expect(hsh['title']).to eq(@resources[0].title)
      end

      it 'shows the private record for superuser' do
        get "/api/datasets/#{CGI.escape(@identifier.to_s)}", {}, default_authenticated_headers
        hsh = response_body_hash
        expect(hsh['versionNumber']).to eq(2)
        expect(hsh['title']).to eq(@resources[1].title)
      end

      it 'shows the private record for the owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        get "/api/datasets/#{CGI.escape(@identifier.to_s)}", {}, default_json_headers.merge('Authorization' => "Bearer #{access_token}")
        hsh = response_body_hash
        expect(hsh['versionNumber']).to eq(2)
        expect(hsh['title']).to eq(@resources[1].title)
      end

      it 'shows the peer review URL when the dataset is in review status' do
        @resources << create(:resource, user_id: @user2.id, tenant_id: @user.tenant_id, identifier_id: @identifier.id)
        @curation_activities << [create(:curation_activity, resource: @resources[2], status: 'in_progress'),
                                 create(:curation_activity, resource: @resources[2], status: 'peer_review')]
        get "/api/datasets/#{CGI.escape(@identifier.to_s)}", {}, default_authenticated_headers
        hsh = response_body_hash
        expect(hsh['sharingLink']).to match(/http/)
      end
    end

    # update, either patch to submit or update metadata
    describe '#update' do
      before(:each) do
        # create a basic dataset to do updates to
        neuter_curation_callbacks!
        mock_ror!
        # mock_repository!, currently this doesn't work right and submissions got put into threadpool background process anyway
        @meta = Fixtures::StashApi::Metadata.new
        @meta.make_minimal
        response_code = post '/api/datasets', @meta.json, default_authenticated_headers
        @ds_info = response_body_hash
        expect(response_code).to eq(201)
        @patch_body = [{ "op": 'replace', "path": '/versionStatus', "value": 'submitted' }].to_json
      end

      describe 'PATCH to submit dataset' do

        it 'submits dataset when the PATCH operation for versionStatus=submitted (superuser & owner)' do
          response_code = patch "/api/datasets/#{CGI.escape(@ds_info['identifier'])}", @patch_body,
                                default_authenticated_headers.merge('Content-Type' => 'application/json-patch+json')
          expect(response_code).to eq(202)
          my_info = response_body_hash
          expect(my_info['versionStatus']).to eq('processing')
          expect(@ds_info['abstract']).to eq(my_info['abstract'])
        end

        it "doesn't submit dataset when the PATCH is not allowed for user (not owner or no permission)" do
          @tenant_ids = StashEngine::Tenant.all.map(&:tenant_id)
          @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'user')
          @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                     owner_id: @user2.id, owner_type: 'StashEngine::User')
          access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
          response_code = patch "/api/datasets/#{CGI.escape(@ds_info['identifier'])}", @patch_body,
                                default_json_headers.merge(
                                  'Content-Type' =>  'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
                                )
          expect(response_code).to eq(401)
          expect(response_body_hash['error']).to eq('unauthorized')
        end

        it "doesn't submit when user isn't logged in" do
          response_code = patch "/api/datasets/#{CGI.escape(@ds_info['identifier'])}", @patch_body,
                                default_json_headers.merge('Content-Type' => 'application/json-patch+json')
          expect(response_code).to eq(401)
        end

        it 'allows submission if done by owner of the dataset (resource)' do
          @tenant_ids = StashEngine::Tenant.all.map(&:tenant_id)
          @user2 = create(:user, tenant_id: @tenant_ids.first, role: 'user')
          @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                     owner_id: @user2.id, owner_type: 'StashEngine::User')
          access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)

          # HACK: in update to make this regular user the owner/editor of this item
          @my_id = StashEngine::Identifier.find(@ds_info['id'])
          @my_id.in_progress_resource.update(current_editor_id: @user2.id, user_id: @user2.id)

          response_code = patch "/api/datasets/#{CGI.escape(@ds_info['identifier'])}", @patch_body,
                                default_json_headers.merge(
                                  'Content-Type' =>  'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
                                )

          expect(response_code).to eq(202)
          expect(response_body_hash['abstract']).to eq(@ds_info['abstract'])
        end
      end

      describe 'PUT to replace metadata for dataset' do

        it 'allows replacing of the metadata for a record' do
          keys_to_extract = %w[title authors abstract]
          modified_metadata = @ds_info.select { |key, _| keys_to_extract.include?(key) }
          modified_metadata['title'] = 'Crows wave goodbye'
          modified_metadata['authors'].first['firstName'] = 'Helen'
          modified_metadata['abstract'] = 'The implications of ambimorphic archetypes have been far-reaching and pervasive.'
          response_code = put "/api/datasets/#{CGI.escape(@ds_info['identifier'])}", modified_metadata.to_json,
                              default_authenticated_headers
          expect(response_code).to eq(200)
          expect(@ds_info['identifier']).to eq(response_body_hash['identifier'])
          expect(response_body_hash['title']).to eq(modified_metadata['title'])
          expect(response_body_hash['authors']).to eq(modified_metadata['authors'])
          expect(response_body_hash['abstract']).to eq(modified_metadata['abstract'])
        end

        it "doesn't allow non-auth users to update" do
          keys_to_extract = %w[title authors abstract]
          modified_metadata = @ds_info.select { |key, _| keys_to_extract.include?(key) }
          modified_metadata['title'] = 'Froozlotter'
          response_code = put "/api/datasets/#{CGI.escape(@ds_info['identifier'])}", modified_metadata.to_json,
                              default_json_headers
          expect(response_code).to eq(401)
        end

        # I'm not going to test every single auth possibility for every action since they use common methods, but
        # just doing a sanity check that the endpoints work and return generally expected items.
      end

      describe 'PUT to upsert a new dataset with a desired DOI' do
        it 'inserts a new dataset with the DOI I love' do
          @meta2 = Fixtures::StashApi::Metadata.new
          @meta2.make_minimal
          desired_doi = 'doi:10.3072/sasquatch.3711'
          response_code = put "/api/datasets/#{CGI.escape(desired_doi)}", @meta2.json, default_authenticated_headers
          expect(response_code).to eq(200)
          expect(response_body_hash['identifier']).to eq(desired_doi)
          expect(response_body_hash['title']).to eq(@meta2.hash['title'])
          expect(response_body_hash['abstract']).to eq(@meta2.hash['abstract'])
        end

        it 'requires a logged in user for upserting new' do
          @meta2 = Fixtures::StashApi::Metadata.new
          @meta2.make_minimal
          desired_doi = 'doi:10.3072/sasquatch.3711'
          response_code = put "/api/datasets/#{CGI.escape(desired_doi)}", @meta2.json, default_json_headers
          expect(response_code).to eq(401)
        end

        # these would also use the same kinds of authorizations as the other variations on PUT/PATCH.
      end
    end

  end
end
# rubocop:enable Metrics/BlockLength, Metrics/ModuleLength

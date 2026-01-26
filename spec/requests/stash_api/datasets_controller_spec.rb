require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'fixtures/stash_api/em_metadata'
require 'cgi'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe DatasetsController, type: :request do
    include Mocks::Aws
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::CurationActivity
    include Mocks::Salesforce
    include Mocks::Datacite

    let!(:user) { create(:user, role: 'superuser') }
    let!(:system_user) { create(:user, id: 0, first_name: 'Dryad', last_name: 'System') }
    let!(:doorkeeper_application) do
      create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                      owner_id: user.id, owner_type: 'StashEngine::User')
    end

    before(:each) do
      create(:tenant_dryad)
      create(:tenant_ucop)
      neuter_curation_callbacks!
      mock_salesforce!
      mock_datacite_gen!
      mock_solr!
      setup_access_token(doorkeeper_application: doorkeeper_application)
    end

    # test creation of a new dataset
    describe '#create' do
      before(:each) do
        @meta = Fixtures::StashApi::Metadata.new
        @meta.make_minimal
      end

      it 'creates a new dataset from minimal metadata (title, author info, abstract)' do
        # the following works for post with headers
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        expect(/doi:10./).to match(output[:identifier])
        hsh = @meta.hash
        expect(hsh[:title]).to eq(output[:title])
        expect(hsh[:abstract]).to eq(output[:abstract])
        in_author = hsh[:authors].first
        out_author = output[:authors].first
        expect(out_author[:email]).to eq(in_author[:email])
        expect(out_author[:affiliation]).to eq(in_author[:affiliation])

        identifier = StashEngine::Identifier.find_by(identifier: output[:identifier].gsub('doi:', ''))
        expect(identifier).not_to be_nil
        expect(identifier.pub_state).to eq('unpublished')
      end

      it 'creates a new dataset from minimal metadata and ordered authors (title, author info, abstract)' do
        @meta.make_minimal_ordered_authors
        # the following works for post with headers
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        expect(/doi:10./).to match(output[:identifier])
        hsh = @meta.hash
        expect(hsh[:title]).to eq(output[:title])
        expect(hsh[:abstract]).to eq(output[:abstract])
        # should be swapped because we put reverse order
        in_author = hsh[:authors].first
        out_author = output[:authors].last
        expect(out_author[:email]).to eq(in_author[:email])
        expect(out_author[:affiliation]).to eq(in_author[:affiliation])
      end

      it 'strips disallowed tags from dataset titles' do
        @meta.add_title('A dataset title that contains <em>italics</em> and <sup>stuff</sup> but not <b>bold</b>')
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output        = response_body_hash
        expect(response_code).to eq(201)
        expect(/doi:10./).to match(output[:identifier])
        expect(output[:title]).to eq('A dataset title that contains <em>italics</em> and <sup>stuff</sup> but not bold')
      end

      it 'creates a new dataset from minimal metadata with funder' do
        # the following works for post with headers
        funder = @meta.add_funder
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        expect(/doi:10./).to match(output[:identifier])
        hsh = @meta.hash
        funder = funder.first
        ret_fund = hsh[:funders].first
        expect(ret_fund[:organization]).to eq(funder[:organization])
        expect(ret_fund[:awardNumber]).to eq(funder[:awardNumber])
        expect(ret_fund[:identifier]).to eq(funder[:identifier])
        expect(ret_fund[:identifierType]).to eq(funder[:identifierType])
      end

      it 'creates a new dataset with specified keywords' do
        @meta.add_keywords(number: 3)
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        expect(output[:keywords]).to be
        expect(output[:keywords].size).to eq(3)
        expect(output[:keywords].first).to eq(@meta.hash[:keywords].first)
        expect(output[:keywords].second).to eq(@meta.hash[:keywords].second)
        expect(output[:keywords].third).to eq(@meta.hash[:keywords].third)
      end

      it 'creates a new dataset with specified field of science' do
        fos = Faker::Science.science(:natural)
        StashDatacite::Subject.create(subject: fos, subject_scheme: 'fos') # the fos field must exist in the database to be recognized
        @meta.add_field(field_name: 'fieldOfScience', value: fos)
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        expect(output[:fieldOfScience]).to eq(fos)
      end

      it 'creates a new dataset with a userId explicitly set by superuser' do
        test_user = StashEngine::User.create(first_name: Faker::Name.first_name,
                                             last_name: Faker::Name.last_name,
                                             email: Faker::Internet.email)
        @meta.add_field(field_name: 'userId', value: test_user.id)
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        expect(output[:userId]).to eq(test_user.reload.orcid)
      end

      it 'creates a new dataset with a userId explicitly set by journal admin' do
        # journal_user is the journal administrator, test_user is the user that will own the dataset
        journal_user = create(:user, tenant_id: 'ucop')
        journal = create(:journal, issn: "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}")
        create(:role, role_object: journal, user: journal_user)
        doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                 owner_id: journal_user.id, owner_type: 'StashEngine::User')
        setup_access_token(doorkeeper_application: doorkeeper_application)
        test_user = StashEngine::User.create(first_name: Faker::Name.first_name,
                                             last_name: Faker::Name.last_name,
                                             email: Faker::Internet.email)
        @meta.add_field(field_name: 'userId', value: test_user.id)
        @meta.add_field(field_name: 'publicationISSN', value: journal.single_issn)
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        expect(output[:userId]).to eq(test_user.reload.orcid)
      end

      it 'creates a new dataset with a secondary ISSN representing the journal' do
        issn_target = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
        issn_secondary = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
        journal = create(:journal, issn: [issn_target, issn_secondary])

        @meta.add_field(field_name: 'publicationISSN', value: issn_secondary)
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)

        ident = StashEngine::Identifier.find(output[:id])
        expect(ident.publication_issn).to eq(issn_target)
        expect(ident.publication_name).to eq(journal.title)
      end

      it 'creates a new basic dataset with related software' do
        @meta.add_related_work(work_type: 'software')
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)

        # check it against the database
        @stash_id = StashEngine::Identifier.find(output[:id])
        @resource = @stash_id.resources.first
        expect(@resource.related_identifiers.first.work_type).to eq('software')
        expect(@resource.related_identifiers.first.related_identifier).to be
      end

      it 'creates a new basic dataset with a placename' do
        @meta.add_place
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)

        # check it against the database
        @stash_id = StashEngine::Identifier.find(output[:id])
        @resource = @stash_id.resources.first
        expect(@resource.geolocations.first.geolocation_place.geo_location_place).to eq(@meta.hash[:locations].first[:place])

        # check it against the return json
        expect(output[:locations].first[:place]).to eq(@meta.hash[:locations].first[:place])
      end

      it 'creates new curation activities and sets the publication date' do
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        @stash_id = StashEngine::Identifier.find(output[:id])
        @resource = @stash_id.resources.last
        expect(@resource.curation_activities.size).to eq(2) # one for default creation, one for the API

        @curation_activity = Fixtures::StashApi::CurationMetadata.new
        dataset_id = CGI.escape(output[:identifier])
        response_code = post "/api/v2/datasets/#{dataset_id}/curation_activity",
                             params: @curation_activity.json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(200)

        @resource.reload
        expect(@resource.curation_activities.size).to eq(3)
        expect(@resource.publication_date).to be
      end

      it 'does not update the publication date if one is already set' do
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        @stash_id = StashEngine::Identifier.find(output[:id])
        @resource = @stash_id.resources.last
        expect(@resource.curation_activities.size).to eq(2)

        # Set a publication date in the past
        publish_date = Time.now - 10.days
        @resource.update!(publication_date: publish_date)

        @curation_activity = Fixtures::StashApi::CurationMetadata.new
        dataset_id = CGI.escape(output[:identifier])
        response_code = post "/api/v2/datasets/#{dataset_id}/curation_activity",
                             params: @curation_activity.json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(200)

        @resource.reload
        expect(@resource.curation_activities.size).to eq(3)
        expect(@resource.publication_date).to be_within(10.days).of(publish_date)
      end

      context 'when submitted twice' do
        it 'does not create duplicates' do
          expect do
            response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
            expect(response_code).to eq(201)

            response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
            expect(response_code).to eq(422)
          end.to change { StashEngine::Resource.count }.by(1)
        end

        it 'returns error' do
          post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
          response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
          expect(response_code).to eq(422)
          output = response_body_hash
          expect(output).to eq({ 'error' => 'A dataset with same information already exists.' })
        end
      end

      context 'with triggerSubmitInvitation set to true' do
        before do
          @meta.add_trigger_invitation(true)
        end

        it 'does not trigger email sending when owner has no email' do
          hash = @meta.hash
          hash[:authors].first[:email] = nil

          response_code = post '/api/v2/datasets.json', params: hash.to_json, headers: default_authenticated_headers
          expect(response_code).to eq(400)
        end

        it 'triggers email sending when owner has email setup' do
          expect(StashApi::ApiMailer).to receive_message_chain(:send_submit_request, :deliver_now)
          post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        end
      end

      context 'with triggerSubmitInvitation set to false' do
        before do
          @meta.add_trigger_invitation(false)
        end

        it 'does not trigger email sending when owner has no email' do
          expect(StashApi::ApiMailer).not_to receive(:send_submit_request)
          post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        end
      end
    end

    # test creation of a new dataset
    describe '#create Editorial Manager' do
      before(:each) do
        @meta = Fixtures::StashApi::EmMetadata.new
        @meta.make_deposit_metadata
      end

      it 'creates a new dataset from EM deposit metadata' do
        response_code = post '/api/v2/em_submission_metadata', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        hsh = @meta.hash
        ident = StashEngine::Identifier.where(identifier: output[:deposit_id]).first
        res = ident.latest_resource

        expect(ident).to be
        expect(ident.publication_name).to eq(hsh[:journal_full_title])
        expect(res.hold_for_peer_review).to be_truthy
        expect(res.authors.first.author_first_name).to eq(hsh[:authors].first[:first_name])
        expect(res.authors.first.author_last_name).to eq(hsh[:authors].first[:last_name])
        expect(res.authors.first.author_orcid).to eq(hsh[:authors].first[:orcid])
        expect(res.authors.first.author_email).to eq(hsh[:authors].first[:email])
        expect(output[:deposit_upload_url]).to be_truthy
      end

      it 'assigns dataset to system user when ORCID is blank' do
        @meta.hash['authors'].first['orcid'] = ''
        response_code = post '/api/v2/em_submission_metadata', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        ident = StashEngine::Identifier.where(identifier: output[:deposit_id]).first
        res = ident.latest_resource

        expect(ident).to be
        expect(res.submitter.id).to eq(system_user.id)
      end

      it 'creates a new dataset from EM submission metadata' do
        @meta.make_submission_metadata
        response_code = post '/api/v2/em_submission_metadata', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        hsh = @meta.hash
        ident = StashEngine::Identifier.where(identifier: output[:deposit_id]).first
        res = ident.latest_resource

        expect(ident).to be
        expect(ident.publication_name).to eq(hsh[:journal_full_title])
        expect(res.authors.first.author_first_name).to eq(hsh[:authors].first[:first_name])

        dd = hsh['deposit_data']
        expect(res.title).to eq(dd['deposit_description'])
        expect(output[:deposit_upload_url]).to be_falsey
      end

      it 'allows update of deposit metadata with new submission metadata' do
        response_code = post '/api/v2/em_submission_metadata', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        ident = StashEngine::Identifier.where(identifier: output[:deposit_id]).first
        res = ident.latest_resource

        @meta.make_submission_metadata
        response_code = post "/api/v2/em_submission_metadata/doi%3A#{ERB::Util.url_encode(ident.identifier)}",
                             params: @meta.json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(201)
        ident.reload
        res.reload
        hsh = @meta.hash
        expect(res.authors.first.author_first_name).to eq(hsh[:authors].first[:first_name])
        dd = hsh['deposit_data']
        expect(res.title).to eq(dd['deposit_description'])
      end

      it 'allows update of deposit metadata using the raw identifier, without <<doi:>>' do
        response_code = post '/api/v2/em_submission_metadata', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        ident = StashEngine::Identifier.where(identifier: output[:deposit_id]).first
        res = ident.latest_resource

        @meta.make_submission_metadata
        response_code = post "/api/v2/em_submission_metadata/#{ERB::Util.url_encode(ident.identifier)}",
                             params: @meta.json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(201)
        ident.reload
        res.reload
        hsh = @meta.hash
        expect(res.authors.first.author_first_name).to eq(hsh[:authors].first[:first_name])
        dd = hsh['deposit_data']
        expect(res.title).to eq(dd['deposit_description'])
      end

      it 'does not update core fields after the user has submitted edits, but does update selected fields' do
        @meta.make_submission_metadata
        response_code = post '/api/v2/em_submission_metadata', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)
        ident = StashEngine::Identifier.where(identifier: output[:deposit_id]).first
        res = ident.latest_resource
        res.resource_states.first.update(resource_state: 'submitted')
        saved_title = res.title
        res.contributors = []
        res.subjects.clear
        @meta.make_submission_metadata # creates a new fake metadata deposit
        response_code = post "/api/v2/em_submission_metadata/doi%3A#{ERB::Util.url_encode(ident.identifier)}",
                             params: @meta.json,
                             headers: default_authenticated_headers
        expect(response_code).to eq(200)
        res.reload
        expect(res.title).to eq(saved_title) # title should not be overwritten
        expect(res.contributors).not_to be_blank
        expect(res.subjects.map(&:subject)).to include(@meta.hash['article']['keywords'].first)
        expect(res.last_curation_activity.note).to include('Funders')
        expect(res.last_curation_activity.note).to include('Keywords')
      end

      it 'updates the status of a peer_review item if the final_disposition is present in the submission metadata' do
        @meta.make_submission_metadata
        response_code = post '/api/v2/em_submission_metadata', params: @meta.json, headers: default_authenticated_headers
        output = response_body_hash
        expect(response_code).to eq(201)

        ident = StashEngine::Identifier.where(identifier: output[:deposit_id]).first
        res = ident.latest_resource
        res.resource_states.first.update(resource_state: 'submitted')
        create(:curation_activity, resource: res, status: 'peer_review')

        @meta.make_submission_metadata
        response_code = post "/api/v2/em_submission_metadata/doi%3A#{ERB::Util.url_encode(ident.identifier)}",
                             params: @meta.json,
                             headers: default_authenticated_headers

        expect(response_code).to eq(200)
      end
    end

    # list of datasets
    describe '#index' do
      before(:each) do
        neuter_curation_callbacks!
        # these tests are very similar to tests in the model controller for identifier for querying this scope

        @identifiers = []
        0.upto(7).each { |_i| @identifiers.push(create(:identifier)) }
        @user1 = create(:user, tenant_id: 'ucop')
        @user2 = create(:user, tenant_id: 'ucop')
        create(:role, user: @user2, role: 'admin', role_object: @user2.tenant)
        @user3 = create(:user, tenant_id: 'ucb', role: 'curator')
        Timecop.travel(Time.now.utc.to_date - 1.day)
        @resources = [
          create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifiers[0].id),
          create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifiers[1].id),
          create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[2].id),
          create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[3].id),
          create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[4].id),
          create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[5].id),
          create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[6].id),
          create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[7].id)
        ]
        Timecop.return
        @resources.insert(1, create(:resource, user_id: @user1.id, tenant_id: @user1.tenant_id, identifier_id: @identifiers[0].id))
        @resources.insert(3, create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[2].id))

        # identifiers[0]
        @curation_activities = [[create(:curation_activity, :in_progress, resource: @resources[0]),
                                 create(:curation_activity, :curation, resource: @resources[0]),
                                 create(:curation_activity, :published, resource: @resources[0])]]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[1]),
                                 create(:curation_activity, :curation, resource: @resources[1])]

        # identifiers[1]
        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[2]),
                                 create(:curation_activity, :curation, resource: @resources[2])]

        # identifiers[2]
        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[3]),
                                 create(:curation_activity, :curation, resource: @resources[3]),
                                 create(:curation_activity, :action_required, resource: @resources[3])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[4]),
                                 create(:curation_activity, :curation, resource: @resources[4]),
                                 create(:curation_activity, :published, resource: @resources[4])]

        # identifiers[3]
        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[5]),
                                 create(:curation_activity, :curation, resource: @resources[5]),
                                 create(:curation_activity, :embargoed, resource: @resources[5])]

        # identifiers[4]
        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[6]),
                                 create(:curation_activity, :curation, resource: @resources[6]),
                                 create(:curation_activity, :withdrawn, resource: @resources[6])]

        # identifiers[5]
        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[7])]

        # identifiers[6]
        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[8]),
                                 create(:curation_activity, :curation, resource: @resources[8]),
                                 create(:curation_activity, :published, resource: @resources[8])]

        # identifiers[7]
        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[9]),
                                 create(:curation_activity, :curation, resource: @resources[9]),
                                 create(:curation_activity, :embargoed, resource: @resources[9])]

        # 5 public datasets
        #
      end

      describe 'user and role permitted scope' do
        it 'gets a list of public datasets (published status is known by curation status)' do
          get '/api/v2/datasets', as: :json
          output = response_body_hash
          expect(output[:count]).to eq(5)
        end

        it 'gets a list of all datasets because superusers are omniscient' do
          get '/api/v2/datasets', headers: default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(@identifiers.count)
        end

        it 'gets a list for admins: public items and private items in their own library roost' do
          @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                    owner_id: @user2.id, owner_type: 'StashEngine::User')
          setup_access_token(doorkeeper_application: @doorkeeper_application)
          get '/api/v2/datasets', headers: default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(6)
          dois = output['_embedded']['stash:datasets'].map { |ds| ds['identifier'] }
          expect(dois).to include(@identifiers[1].to_s) # this would be private otherwise based on curation status
        end

        it 'gets a list for an individual user for public and his own' do
          @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                    owner_id: @user1.id, owner_type: 'StashEngine::User')
          setup_access_token(doorkeeper_application: @doorkeeper_application)
          get '/api/v2/datasets', headers: default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(6)
          dois = output['_embedded']['stash:datasets'].map { |ds| ds['identifier'] }
          expect(dois).to include(@identifiers[1].to_s) # this would be private otherwise based on curation status
        end

        it 'gets a list for journal admins: public items and private items associated with the journal' do
          # set up user4 as a journal admin, and identifiers[1] as belonging to that journal
          user4 = create(:user, tenant_id: 'ucop')
          journal = create(:journal)
          create(:role, role_object: journal, user: user4)
          create(:resource_publication, publication_issn: journal.single_issn, resource: create(:resource, identifier: @identifiers[1]))
          @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                    owner_id: user4.id, owner_type: 'StashEngine::User')
          setup_access_token(doorkeeper_application: @doorkeeper_application)
          get '/api/v2/datasets', headers: default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(6)
          dois = output['_embedded']['stash:datasets'].map { |ds| ds['identifier'] }
          # this would be private based on curation status, but the journal admin should be able to see it
          expect(dois).to include(@identifiers[1].to_s)
        end

        it 'correctly pages index results' do
          # There are 8 results total
          get '/api/v2/datasets?page=2&per_page=2', headers: default_authenticated_headers
          output = response_body_hash
          expect(output['_links']['last']['href']).to include('page=4')

          get '/api/v2/datasets?page=2&per_page=3', headers: default_authenticated_headers
          output = response_body_hash
          expect(output['_links']['last']['href']).to include('page=3')
        end
      end

      describe 'list display is different than single item display' do
        it "doesn't show changedFields for every item in long list with expensive operation to compare versions" do
          get '/api/v2/datasets', headers: default_authenticated_headers
          output = response_body_hash
          expect(output['_embedded']['stash:datasets'][0]['changedFields']).to be_nil
        end
      end

      describe 'shows appropriate latest resource metadata under identifier based on user' do
        before(:each) do
          # versions not getting set correctly for these two resources for some reason
          @resources[0].stash_version.update(version: 1)
          @resources[1].stash_version.update(version: 2)
        end

        it 'shows the first, published version for a public dataset by default' do
          get '/api/v2/datasets', as: :json
          hsh = response_body_hash

          # the first identifier
          expect(hsh['_embedded']['stash:datasets'][0]['identifier']).to eq(@identifiers[0].to_s)

          expect(hsh['_embedded']['stash:datasets'][0]['title']).to eq(@resources[0].title)

          # the second (embargoed) version
          expect(hsh['_embedded']['stash:datasets'][0]['versionNumber']).to eq(1)
        end

        it 'shows the 2nd, unpublished version to superusers who see everything by default' do

          get '/api/v2/datasets', headers: default_authenticated_headers
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
          get '/api/v2/datasets', params: { 'curationStatus' => 'curation' }, headers: default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(2)
          expect(output['_embedded']['stash:datasets'].first['identifier']).to eq(@identifiers[0].to_s)
        end

        it 'reduces scope to a publisher ISSN' do
          journal = create(:journal, issn: '0001-0001')
          create(:resource_publication, publication_issn: journal.single_issn, resource: create(:resource, identifier: @identifiers[5]))
          get '/api/v2/datasets', params: { 'publicationISSN' => journal.single_issn }, headers: default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(1)
          expect(output['_embedded']['stash:datasets'].first['identifier']).to eq(@identifiers[5].to_s)
        end

        it 'reduces scope to a manuscriptNumber' do
          create(:internal_datum, identifier_id: @identifiers[5].id, data_type: 'manuscriptNumber', value: 'manuscript123')
          create(:resource_publication, manuscript_number: 'manuscript123', resource: create(:resource, identifier: @identifiers[5]))
          get '/api/v2/datasets', params: { 'manuscriptNumber' => 'manuscript123' }, headers: default_authenticated_headers
          output = response_body_hash
          expect(output[:count]).to eq(1)
          expect(output['_embedded']['stash:datasets'].first['identifier']).to eq(@identifiers[5].to_s)
        end

      end
    end

    # search
    describe '#search' do
      before(:each) do
        @ident = create(:identifier)
        @res   = create(:resource, identifier: @ident, tenant_id: 'dryad')
        create(:curation_activity, :published, resource: @res, created_at: '2020-01-04')
        mock_solr!(include_identifier: @ident)
      end

      it 'returns search results' do
        get '/api/v2/search?q=data', headers: default_authenticated_headers
        output = response_body_hash
        # the mocked solr response has 5 results
        expect(output['_embedded']['stash:datasets'].size).to eq(5)
      end

      it 'formats a search result correctly' do
        get '/api/v2/search?q=data', headers: default_authenticated_headers
        output = response_body_hash
        result = output['_embedded']['stash:datasets'].first
        expect(result['identifier']).to eq("doi:#{@ident.identifier}")
        expect(result['title']).to eq(@res.title)
        expect(result['curationStatus']).to eq('Published')
      end

      it 'correctly pages search results' do
        # the mocked solr response reports that there are 110 total results, but only
        # includes 5 of those results
        get '/api/v2/search?q=data&page=2&per_page=6', headers: default_authenticated_headers
        output = response_body_hash
        expect(output['_links']['last']['href']).to include('page=19')
        expect(output['_links']['next']['href']).to include('page=3')

        get '/api/v2/search?q=data&page=2&per_page=11', headers: default_authenticated_headers
        output = response_body_hash
        expect(output['_links']['last']['href']).to include('page=10')

        get '/api/v2/search?q=data&page=2&per_page=5', headers: default_authenticated_headers
        output = response_body_hash
        expect(output['_links']['last']['href']).to include('page=22')
      end

      it 'allows searches by affiliation' do
        target_ror = @res.authors.first.affiliation.ror_id
        get "/api/v2/search?affiliation=#{target_ror}", headers: default_authenticated_headers
        output = response_body_hash
        result = output['_embedded']['stash:datasets'].first
        expect(result['authors'].first['affiliationROR']).to eq(target_ror)
      end

      it 'allows searches by tenant' do
        target_ror = @res.authors.first.affiliation.ror_id
        create(:tenant_ror_org, tenant_id: @res.tenant.id, ror_id: target_ror)
        get "/api/v2/search?tenant=#{@res.tenant.id}", headers: default_authenticated_headers
        output = response_body_hash
        result = output['_embedded']['stash:datasets'].first
        expect(result['authors'].first['affiliationROR']).to eq(target_ror)
      end

      it 'allows searches by modifiedSince' do
        get '/api/v2/search?modifiedSince=2020-10-08T10:24:53Z', headers: default_authenticated_headers
        output = response_body_hash
        result = output['_embedded']['stash:datasets'].last
        expect(result['identifier']).to eq("doi:#{@ident.identifier}")
      end

      it 'allows searches by modifiedBefore' do
        time = 2.day.from_now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
        get "/api/v2/search?modifiedBefore=#{time}", headers: default_authenticated_headers
        output = response_body_hash
        expect(output['_embedded']['stash:datasets'].size).to eq(1)
      end

      it 'allows searches by relatedWorkIdentifier' do
        get '/api/v2/search?relatedWorkIdentifier=*123*', headers: default_authenticated_headers
        output = response_body_hash
        expect(output['_embedded']['stash:datasets'].size).to eq(1)
      end

      it 'passes a sanitised query to solr' do
        solr_mock = instance_double(RSolr::Client)
        allow(RSolr).to receive(:connect).and_return(solr_mock)
        allow(solr_mock).to receive(:paginate).and_return(JSON.parse(default_results))

        get '/api/v2/search?q=system+%28fo%29', headers: default_authenticated_headers

        expect(solr_mock).to have_received(:paginate).with(
          1,
          20,
          'select',
          params: {
            facet: false,
            q: 'system \\(fo\\)',
            fq: [],
            fl: 'dc_identifier_s'
          }
        )
      end
    end

    # view single dataset
    describe '#show' do
      before(:each) do
        neuter_curation_callbacks!

        @tenant_ids = StashEngine::Tenant.enabled.map(&:id)

        # I think @user is created for use with doorkeeper already
        @user2 = create(:user, tenant_id: @tenant_ids.first)

        @identifier = create(:identifier)
        Timecop.travel(Time.now.utc.to_date - 1.day)
        @resources = [create(:resource, user_id: @user2.id, tenant_id: user.tenant_id, identifier_id: @identifier.id)]
        Timecop.travel(Time.now.utc + 23.hours)
        @resources.push(create(:resource, user_id: @user2.id, tenant_id: user.tenant_id, identifier_id: @identifier.id))
        Timecop.return
        @curation_activities = [[create(:curation_activity, :in_progress, resource: @resources[0]),
                                 create(:curation_activity, :curation, resource: @resources[0]),
                                 create(:curation_activity, :published, resource: @resources[0])]]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[1]),
                                 create(:curation_activity, :curation, resource: @resources[1])]

        # set versions correctly seems not correctly working unless created another way.
        @resources[0].stash_version.update(version: 1)
        @resources[1].stash_version.update(version: 2)
      end

      it 'shows a public record for a created identifier/resource' do
        get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}", as: :json # not logged in
        hsh = response_body_hash
        expect(hsh['versionNumber']).to eq(1)
        expect(hsh['title']).to eq(@resources[0].title)
        expect(hsh['editLink']).to eq(nil)
      end

      it 'shows tags in dataset titles' do
        @resources[0].update(title: 'A dataset title that contains <em>italics</em> and <sup>stuff</sup>')
        get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}", as: :json # not logged in
        hsh = response_body_hash
        expect(hsh['title']).to eq(@resources[0].title)
      end

      it 'shows the dataset with the correct json type, even if not set explicitly in accept headers' do
        get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}", headers: { 'ACCEPT' => '*/*' }
        expect(response.headers['Content-type']).to eq('application/json; charset=utf-8')
      end

      it 'shows the private record for superuser' do
        @identifier.edit_code = Faker::Number.number(digits: 6)
        @identifier.save
        get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}", headers: default_authenticated_headers
        hsh = response_body_hash
        expect(hsh['versionNumber']).to eq(2)
        expect(hsh['title']).to eq(@resources[1].title)
        expect(hsh['editLink']).to include(@identifier.edit_code)
      end

      # It's difficult to test the methods in ApiApplicationController except indirectly.  This tests that items that
      # would normally have greater superuser viewing are limited to user role for 3rd party proxy for a user through
      # Authorization grant type.  The other tests are all about our "Typical" user that is Client Credentials grant.
      it "doesn't show the private record for superusers when using Authorzation Code Grant (3rd party user proxy)" do
        # this also indirectly tests the optional_api_user which changes based on login method
        # set access_token to proxy for user
        doorkeeper_application.access_tokens.first.update(resource_owner_id: doorkeeper_application.owner_id)
        # reset to different grant type where it's not owned by api user
        doorkeeper_application.update(owner_id: nil, owner_type: nil)
        get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}", headers: default_authenticated_headers
        hsh = response_body_hash
        expect(hsh['versionNumber']).to eq(1) # only shows published one, not later one that isn't
        expect(hsh['title']).to eq(@resources[0].title)
      end

      it 'shows the private record for the owner' do
        @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                   owner_id: @user2.id, owner_type: 'StashEngine::User')
        access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
        get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}", headers: default_json_headers.merge('Authorization' => "Bearer #{access_token}")
        hsh = response_body_hash
        expect(hsh['versionNumber']).to eq(2)
        expect(hsh['title']).to eq(@resources[1].title)
      end

      it 'shows the peer review URL when the dataset is in review status' do
        @resources << create(:resource, user_id: @user2.id, tenant_id: user.tenant_id, identifier_id: @identifier.id)
        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[2]),
                                 create(:curation_activity, :peer_review, resource: @resources[2])]
        get "/api/v2/datasets/#{CGI.escape(@identifier.to_s)}", headers: default_authenticated_headers
        hsh = response_body_hash
        expect(hsh['sharingLink']).to match(/http/)
      end
    end

    # update, either patch to submit or update metadata
    describe '#update' do
      before(:each) do
        # create a basic dataset to do updates to
        neuter_curation_callbacks!
        mock_aws!
        @meta = Fixtures::StashApi::Metadata.new
        @meta.make_minimal
        response_code = post '/api/v2/datasets', params: @meta.json, headers: default_authenticated_headers
        @ds_info = response_body_hash
        expect(response_code).to eq(201)
        my_id = StashEngine::Identifier.find(@ds_info['id'])
        @res = my_id.in_progress_resource
        @res.update(title: 'Sufficiently complex title for test dataset')
        @res.update(data_files: [create(:data_file, file_state: 'copied'),
                                 create(:data_file, file_state: 'copied')])
        @patch_body = [{ op: 'replace', path: '/versionStatus', value: 'submitted' }].to_json
      end

      describe 'PATCH to submit dataset' do
        xit 'submits dataset when the PATCH operation for versionStatus=submitted (superuser & owner)' do
          response_code = patch "/api/v2/datasets/#{CGI.escape(@ds_info['identifier'])}",
                                params: @patch_body,
                                headers: default_authenticated_headers.merge('Content-Type' => 'application/json-patch+json')
          expect(response_code).to eq(202)
          my_info = response_body_hash
          expect(my_info['versionStatus']).to eq('processing')
          expect(@ds_info['abstract']).to eq(my_info['abstract'])
        end

        it "doesn't submit dataset when the PATCH is not allowed for user (not owner or no permission)" do
          @tenant_ids = StashEngine::Tenant.enabled.map(&:id)
          @user2 = create(:user, tenant_id: @tenant_ids.first)
          @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                     owner_id: @user2.id, owner_type: 'StashEngine::User')
          access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)
          response_code = patch "/api/v2/datasets/#{CGI.escape(@ds_info['identifier'])}",
                                params: @patch_body,
                                headers: default_json_headers.merge(
                                  'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
                                )
          expect(response_code).to eq(401)
          expect(response_body_hash['error']).to eq('unauthorized')
        end

        it "doesn't submit when user isn't logged in" do
          response_code = patch "/api/v2/datasets/#{CGI.escape(@ds_info['identifier'])}",
                                params: @patch_body,
                                headers: default_json_headers.merge('Content-Type' => 'application/json-patch+json')
          expect(response_code).to eq(401)
        end

        context 'when submission is allowed (done by owner of the dataset)' do
          before do
            @tenant_ids = StashEngine::Tenant.enabled.map(&:id)
            user2 = create(:user, tenant_id: @tenant_ids.first, orcid: @ds_info['authors'].first['orcid'])
            @doorkeeper_application2 = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                       owner_id: user2.id, owner_type: 'StashEngine::User')
            @access_token = get_access_token(doorkeeper_application: @doorkeeper_application2)

            # HACK: in update to make this regular user the owner/editor of this item
            create(:description, resource: @res, description_type: 'technicalinfo')
            @res.update(current_editor_id: user2.id)
            @res.submitter = user2.id
          end

          context 'when there is no fee to pay' do
            before do
              allow_any_instance_of(ResourceFeeCalculatorService).to receive(:calculate).and_return({ total: 0, storage_fee_label: 'Submission fee' })
            end

            it 'succeeds' do
              response_code = patch "/api/v2/datasets/#{CGI.escape(@ds_info['identifier'])}",
                                    params: @patch_body,
                                    headers: default_json_headers.merge(
                                      'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{@access_token}"
                                    )
              expect(response_code).to eq(202)
              expect(response_body_hash['abstract']).to eq(@ds_info['abstract'])
            end
          end

          context 'when there is a fee to pay' do
            before do
              allow_any_instance_of(ResourceFeeCalculatorService).to receive(:calculate).and_return(
                { total: 123,
                  storage_fee_label: 'Submission fee' }
              )
            end

            it 'allows submission if done by owner of the dataset (resource)' do
              response_code = patch "/api/v2/datasets/#{CGI.escape(@ds_info['identifier'])}",
                                    params: @patch_body,
                                    headers: default_json_headers.merge(
                                      'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{@access_token}"
                                    )
              expect(response_code).to eq(403)
              expect(response_body_hash[:error]).to eq('You need to pay a Submission fee of $123 in order to submit.')
            end
          end
        end
      end

      describe 'PUT to replace metadata for dataset' do

        it 'allows replacing of the metadata for a record' do
          keys_to_extract = %w[title authors abstract]
          modified_metadata = @ds_info.select { |key, _| keys_to_extract.include?(key) }
          modified_metadata['title'] = 'Crows wave goodbye'
          modified_metadata['authors'].first['firstName'] = 'Helen'
          modified_metadata['abstract'] = 'The implications of ambimorphic archetypes have been far-reaching and pervasive.'
          response_code = put "/api/v2/datasets/#{CGI.escape(@ds_info['identifier'])}",
                              params: modified_metadata.to_json,
                              headers: default_authenticated_headers
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
          response_code = put "/api/v2/datasets/#{CGI.escape(@ds_info['identifier'])}",
                              params: modified_metadata.to_json,
                              as: :json
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
          response_code = put "/api/v2/datasets/#{CGI.escape(desired_doi)}",
                              params: @meta2.json,
                              headers: default_authenticated_headers
          expect(response_code).to eq(200)
          expect(response_body_hash['identifier']).to eq(desired_doi)
          expect(response_body_hash['title']).to eq(@meta2.hash['title'])
          expect(response_body_hash['abstract']).to eq(@meta2.hash['abstract'])
        end

        it 'requires a logged in user for upserting new' do
          @meta2 = Fixtures::StashApi::Metadata.new
          @meta2.make_minimal
          desired_doi = 'doi:10.3072/sasquatch.3711'
          response_code = put "/api/v2/datasets/#{CGI.escape(desired_doi)}",
                              params: @meta2.json,
                              as: :json
          expect(response_code).to eq(401)
        end
        # these would also use the same kinds of authorizations as the other variations on PUT/PATCH.
      end

      describe 'PATCH to update curationStatus or publicationISSN' do
        let!(:access_token) { get_access_token(doorkeeper_application: doorkeeper_application) }

        before(:each) do
          allow_any_instance_of(ResourceFeeCalculatorService).to receive(:calculate).and_return({ total: 0, storage_fee_label: 'Submission fee' })

          # create a dataset in peer-review status
          # @access_token           = get_access_token(doorkeeper_application: doorkeeper_application)
          @identifier = create(:identifier)
          @res = create(:resource, identifier: @identifier, user: user)
          create(:description, resource: @res, description_type: 'technicalinfo')
          @res.update(data_files: [create(:data_file, file_state: 'copied'),
                                   create(:data_file, file_state: 'copied')])
          @res.authors.first.update(author_orcid: user.orcid)
          @res.subjects << [create(:subject), create(:subject), create(:subject)]
          @ca = create(:curation_activity, resource: @res, status: 'peer_review')
          @identifier.reload
        end

        it 'allows curationStatus to be updated' do
          expect(@res.current_curation_status).to eq('peer_review')

          @patch_body = [{ op: 'replace', path: '/curationStatus', value: 'queued' }].to_json
          response_code = patch "/api/v2/datasets/doi%3A#{CGI.escape(@identifier.identifier)}",
                                params: @patch_body,
                                headers: default_json_headers.merge(
                                  'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
                                )
          expect(response_code).to eq(200)
          expect(@res.current_curation_status).to eq('queued')
        end

        it 'does not allow curationStatus to be updated if the item is already published' do
          @ca = create(:curation_activity, :published, resource: @res)
          expect(@res.current_curation_status).to eq('published')

          @patch_body = [{ op: 'replace', path: '/curationStatus', value: 'queued' }].to_json
          response_code = patch "/api/v2/datasets/doi%3A#{CGI.escape(@identifier.identifier)}",
                                params: @patch_body,
                                headers: default_json_headers.merge(
                                  'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
                                )
          expect(response_code).to eq(200)
          expect(@res.current_curation_status).to eq('published')
        end

        it 'allows publicationISSN to be updated, to claim a dataset for a journal' do
          expect(@identifier.publication_issn).to eq(nil)

          # use multiple ISSNs to test that the patch process sets the journal's primary ISSN (issn_target)
          # even when it is presented with an alternate (issn_test)
          issn_target = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
          issn_test = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
          journal = create(:journal, issn: [issn_target, issn_test])

          @patch_body = [{ op: 'replace', path: '/publicationISSN', value: issn_test }].to_json
          response_code = patch "/api/v2/datasets/doi%3A#{CGI.escape(@identifier.identifier)}",
                                params: @patch_body,
                                headers: default_json_headers.merge(
                                  'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
                                )
          expect(response_code).to eq(200)
          @identifier.reload
          expect(@identifier.publication_issn).to eq(issn_target)
          expect(@identifier.publication_name).to eq(journal.title)
        end

        it 'allows publicationISSN to be removed with a nil value' do
          new_issn = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
          create(:resource_publication, publication_issn: new_issn, resource: @res)
          expect(@identifier.publication_issn).to eq(new_issn)
          @patch_body = [{ op: 'replace', path: '/publicationISSN', value: '' }].to_json
          response_code = patch "/api/v2/datasets/doi%3A#{CGI.escape(@identifier.identifier)}",
                                params: @patch_body,
                                headers: default_json_headers.merge(
                                  'Content-Type' => 'application/json-patch+json', 'Authorization' => "Bearer #{access_token}"
                                )
          @identifier.reload
          expect(response_code).to eq(200)
          expect(@identifier.publication_issn).to eq(nil)
        end
      end
    end

    describe '#download' do
      let(:identifier) { create(:identifier) }
      let!(:resource) { create(:resource, identifier: identifier, file_view: file_view, total_file_size: 10) }
      let(:file_view) { true }

      subject do
        get "/api/v2/datasets/doi%3A#{CGI.escape(identifier.identifier)}/download", headers: default_authenticated_headers
      end

      context 'when resource can be downloaded' do
        before do
          allow_any_instance_of(Aws::Sigv4::Signer).to receive(:presign_url).and_return('download/file_urel.zip')

          resource.current_state = 'submitted'
          subject
        end

        context 'when resource is under max api_zip_size' do
          it 'downloads the resource' do
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('download/file_urel.zip')
          end
        end

        context 'when resource is over max api_zip_size' do
          let!(:resource) do
            create(:resource, identifier: identifier, file_view: file_view, total_file_size: APP_CONFIG[:maximums][:api_zip_size] + 1)
          end

          it 'returns an error' do
            expect(response).to have_http_status(405)
            expect(response.body).to eq('The dataset is too large for zip file generation. Please download each file individually.')
          end
        end
      end

      context 'when resource can not be downloaded' do
        let!(:file_view) { false }

        it 'returns 404 and a message' do
          subject

          expect(response).to have_http_status(:not_found)
          expect(response.body).to eq('Download for this version of the dataset is unavailable')
        end
      end
    end

    describe '#set_internal_datum' do
      let(:identifier) { create(:identifier) }
      let!(:resource) { create(:resource, identifier: identifier) }
      let(:data_type) { 'manuscriptNumber' }

      subject do
        post "/api/v2/datasets/doi%3A#{CGI.escape(identifier.identifier)}/set_internal_datum",
             params: { data_type: @data_type || data_type, value: 'new_value' }.to_json,
             headers: default_authenticated_headers
      end

      context 'when data type allows multiple entries' do
        %w[mismatchedDOI duplicateItem formerManuscriptNumber].each do |data_type|
          it "returns an error for `#{data_type}`" do
            @data_type = data_type
            subject

            expect(response).to have_http_status(:not_found)
            expect(response_body_hash[:error]).to eq("#{data_type} allows multiple entries, use add_internal_datum")
          end
        end
      end

      context 'when data type does not allow multiple entries' do
        context 'when datum entry exists' do
          let!(:datum) { create(:internal_datum, identifier_id: identifier.id, data_type: data_type, value: 'old_value') }

          it 'sets the datum value' do
            subject

            expect(response).to have_http_status(:ok)
            expect(datum.reload.value).to eq('new_value')
          end
        end

        context 'when datum entry does not exist' do
          it 'sets the datum value' do
            subject

            expect(response).to have_http_status(:ok)
            info = identifier.internal_data.where(data_type: data_type)
            expect(info.count).to eq(1)
            expect(info.first).to be_a(StashEngine::InternalDatum)
            expect(info.first.value).to eq('new_value')
          end
        end
      end
    end

    describe '#add_internal_datum' do
      let(:identifier) { create(:identifier) }
      let!(:resource) { create(:resource, identifier: identifier) }
      let(:data_type) { 'manuscriptNumber' }

      subject do
        post "/api/v2/datasets/doi%3A#{CGI.escape(identifier.identifier)}/add_internal_datum",
             params: { data_type: data_type, value: 'new_value' }.to_json,
             headers: default_authenticated_headers
      end

      context 'when data type allows multiple entries' do
        let(:data_type) { 'mismatchedDOI' }

        it 'sets the datum value' do
          subject

          expect(response).to have_http_status(:ok)
          expect(identifier.internal_data.last.value).to eq('new_value')
        end
      end

      context 'when data type does not allow multiple entries' do
        context 'when datum entry exists' do
          let!(:datum) { create(:internal_datum, identifier_id: identifier.id, data_type: data_type, value: 'old_value') }

          it 'returns an error for `manuscriptNumber`' do
            subject

            expect(response).to have_http_status(:not_found)
            expect(response_body_hash[:error]).to eq("#{data_type} does not allow multiple entries, use set_internal_datum")
          end
        end
      end
    end
  end
end

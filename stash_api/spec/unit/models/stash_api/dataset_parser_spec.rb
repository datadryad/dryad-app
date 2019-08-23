require 'db_spec_helper'
require 'byebug'

module StashApi
  RSpec.describe DatasetParser do
    before(:each) do
      # app = double(Rails::Application)
      # allow(app).to receive(:stash_mount).and_return('/api/v2')
      # TODO: We need to figure out how to load the other engines without errors (spec_helper probably)
      # allow(StashEngine).to receive(:app).and_return(app)

      @tenants = StashEngine.tenants
      StashEngine.tenants = begin
        tenants = HashWithIndifferentAccess.new
        tenant_hash = YAML.load_file(::File.join(ENGINES['stash_engine'], 'spec/data/tenant-example.yml'))['test']
        tenants['exemplia'] = HashWithIndifferentAccess.new(tenant_hash)
        tenants
      end

      @user = StashEngine::User.create(
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        tenant_id: 'exemplia',
        orcid: '1234-5678-9876-5432'
      )

      @user2 = StashEngine::User.create(
        first_name: 'Gordon',
        last_name: 'Madsen',
        email: 'gmadsen@example.org',
        tenant_id: 'exemplia',
        orcid: '555-1212'
      )

      @basic_metadata = {
        'title' => 'Visualizing Congestion Control Using Self-Learning Epistemologies',
        'authors' => [
          {
            'firstName' => 'Wanda',
            'lastName' => 'Jackson',
            'email' => 'wanda.jackson@example.com',
            'affiliation' => 'University of the Example'
          }
        ],
        'abstract' =>
              'Cyberneticists agree that concurrent models are an interesting new topic in the field of machine learning.',
        'userId' => @user2.id,
        'invoiceId' => 'invoice-123'
      }.with_indifferent_access

      @update_metadata = {
        'title' => 'Changed my Dataset Title',
        'authors' => [
          {
            'firstName' => 'Grok',
            'lastName' => 'Snorville',
            'email' => 'grok.snorville@example.com',
            'affiliation' => 'University of Real Estate Purchases'
          }
        ],
        'abstract' =>
              'We are a for-profit university.'
      }.with_indifferent_access

      # mock doubles for the repo
      repo = double('some repo')
      allow(repo).to receive(:mint_id).and_return('doi:12345/67890')
      allow(StashEngine).to receive(:repository).and_return(repo)

      dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
      @stash_identifier = dp.parse

      allow_any_instance_of(Stash::Organization::Ror).to receive(:find_first_by_ror_name).and_return(
        id: 'abcd', name: 'Test Ror Organization'
      )
    end

    describe :parses_basics do

      it 'creates a stash_engine_identifier' do
        expect(@stash_identifier.identifier).to match(%r{10.5072/dryad\..{8}})
      end

      it 'creates a resource with correct information' do
        expect(@stash_identifier.resources.count).to eq(1)
        resource = @stash_identifier.resources.first
        expect(resource.title).to eq(@basic_metadata[:title])
      end

      it 'creates the author as specified' do
        resource = @stash_identifier.resources.first
        expect(resource.authors.count).to eq(1)
        author = resource.authors.first
        expect(author.author_first_name).to eq(@basic_metadata[:authors].first['firstName'])
        expect(author.author_last_name).to eq(@basic_metadata[:authors].first['lastName'])
        expect(author.author_email).to eq(@basic_metadata[:authors].first['email'])
      end

      it 'allows bad (not blank, but invalid) emails' do
        @basic_metadata = {
          'title' => 'Visualizing Congestion Control Using Self-Learning Epistemologies',
          'authors' => [
            {
              'firstName' => 'Wanda',
              'lastName' => 'Jackson',
              'email' => 'grog-to-drink',
              'affiliation' => 'never'
            }
          ],
          'abstract' =>
                'Cyberneticists agree that concurrent models are an interesting new topic in the field of machine learning.',
          'userId' => @user2.id
        }.with_indifferent_access

        dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
        @stash_identifier = dp.parse
        resource = @stash_identifier.resources.first
        author = resource.authors.first
        expect(author.author_first_name).to eq(@basic_metadata[:authors].first['firstName'])
        expect(author.author_last_name).to eq(@basic_metadata[:authors].first['lastName'])
        expect(author.author_email).to eq(@basic_metadata[:authors].first['email'])
      end

      it 'creates the abstract' do
        resource = @stash_identifier.resources.first
        des = resource.descriptions.first
        expect(des.description).to eq(@basic_metadata[:abstract])
        expect(des.description_type).to eq('abstract')
      end

      it 'sets the owner' do
        resource = @stash_identifier.resources.first
        expect(resource.user_id). to eq(@user2.id)
        expect(resource.current_editor_id).to eq(@user2.id)
      end

      it 'puts the invoiceId on the identifier' do
        expect(@stash_identifier.invoice_id). to eq('invoice-123')
      end
    end

    describe 'identifier handling' do
      it 'allows an identifier to be specified for a new parsed dataset' do
        # override typical parsing and instead, set a DOI
        dp = DatasetParser.new(hash: @basic_metadata, user: @user, id_string: 'doi:9876/4321')
        @stash_identifier = dp.parse
        expect(@stash_identifier.identifier).to eq('9876/4321')
        expect(@stash_identifier.in_progress_resource.title).to eq(@basic_metadata[:title])
      end

      it 'updates an existing dataset with a new in-progress version' do
        resource = @stash_identifier.in_progress_resource
        resource.update(skip_emails: true)
        resource.current_state = 'submitted' # make it look like the first was successfully submitted, so this next will be new version
        resource.save
        # this is what happens in the controller if an update to an existing identifier that has last successfully submitted (completed) version
        # I can imagine, that this might be incorporated into the DatasetParser object instead
        new_resource = resource.amoeba_dup
        new_resource.current_editor_id = @user.id
        new_resource.save!
        @resource = new_resource

        dp = DatasetParser.new(hash: @update_metadata, id: @stash_identifier, user: @user)
        @stash_identifier = dp.parse
        expect(@stash_identifier.resources.count).to eq(2)

        editing_resource = @stash_identifier.in_progress_resource

        expect(editing_resource.title).to eq(@update_metadata[:title])
        expect(@user.id).to eq(editing_resource.user_id)

        author = editing_resource.authors.first
        expect(author.author_first_name).to eq(@update_metadata[:authors].first['firstName'])
        expect(author.author_last_name).to eq(@update_metadata[:authors].first['lastName'])
        expect(author.author_email).to eq(@update_metadata[:authors].first['email'])

        des = editing_resource.descriptions.first
        expect(des.description).to eq(@update_metadata[:abstract])
      end
    end

    describe 'skip datacite update' do
      it 'defaults to false' do
        dp = DatasetParser.new(hash: {}, user: @user, id_string: 'doi:10.231/jkhaha')
        stash_identifier = dp.parse
        resource = stash_identifier.in_progress_resource
        expect(resource.skip_datacite_update).to eq(false)
      end

      it 'will set it to true' do
        dp = DatasetParser.new(hash: { 'skipDataciteUpdate' => true }, user: @user, id_string: 'doi:10.231/jkhaha')
        stash_identifier = dp.parse
        resource = stash_identifier.in_progress_resource
        expect(resource.skip_datacite_update).to eq(true)
      end
    end
  end
end

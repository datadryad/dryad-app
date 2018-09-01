require 'db_spec_helper'

module StashApi
  RSpec.describe DatasetParser do
    before(:each) do
      # app = double(Rails::Application)
      # allow(app).to receive(:stash_mount).and_return('/api')
      # TODO: We need to figure out how to load the other engines without errors (spec_helper probably)
      # allow(StashEngine).to receive(:app).and_return(app)

      @tenants = StashEngine.tenants
      StashEngine.tenants = begin
        tenants = HashWithIndifferentAccess.new
        tenant_hash = YAML.load_file(::File.join(ENGINES['stash_engine'], 'spec/data/tenant-example.yml'))['test']
        tenants['exemplia'] = HashWithIndifferentAccess.new(tenant_hash)
        tenants
      end

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
              'Cyberneticists agree that concurrent models are an interesting new topic in the field of machine learning.'
      }.with_indifferent_access

      @user = StashEngine::User.create(
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        tenant_id: 'exemplia',
        orcid: '1234-5678-9876-5432'
      )

      # mock doubles for the repo
      repo = double('some repo')
      allow(repo).to receive(:mint_id).and_return('doi:12345/67890')
      allow(StashEngine).to receive(:repository).and_return(repo)

      dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
      @stash_identifier = dp.parse
    end

    describe :parses_basics do

      it 'creates a stash_engine_identifier' do
        expect(@stash_identifier.identifier).to eq('12345/67890')
      end

      it 'creates a resource with correct information' do
        expect(@stash_identifier.resources.count).to eq(1)
        resource = @stash_identifier.resources.first
        expect(resource.title).to eq(@basic_metadata[:title])
        expect(@user.id).to eq(resource.user_id)
      end

      it 'creates the author as specified' do
        resource = @stash_identifier.resources.first
        expect(resource.authors.count).to eq(1)
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
    end
  end
end

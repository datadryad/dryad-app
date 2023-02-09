require 'byebug'

module StashApi
  RSpec.describe DatasetParser do
    include Mocks::Datacite
    include Mocks::Tenant
    include Mocks::Salesforce

    before(:each) do
      mock_datacite!
      mock_salesforce!
      allow(Stash::Doi::IdGen).to receive(:mint_id).and_return('doi:10.5072/dryad.12345678')

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
            'orcid' => '0000-1111-2222-3333',
            'affiliation' => 'University of the Example'
          }
        ],
        'abstract' =>
              'Cyberneticists agree that concurrent models are an interesting new topic in the field of machine learning.',
        'userId' => @user2.id,
        'publicationISSN' => '0000-1111',
        'publicationName' => 'Some Great Journal',
        'manuscriptNumber' => 'ABC123',
        'paymentId' => 'invoice-123',
        'paymentType' => 'stripe'
      }.with_indifferent_access

      @update_metadata = {
        'title' => 'Changed my Dataset title',
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

      dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
      @stash_identifier = dp.parse
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

      it 'creates the basic author metadata as specified' do
        resource = @stash_identifier.resources.first
        expect(resource.authors.count).to eq(1)
        author = resource.authors.first
        expect(author.author_first_name).to eq(@basic_metadata[:authors].first['firstName'])
        expect(author.author_last_name).to eq(@basic_metadata[:authors].first['lastName'])
        expect(author.author_email).to eq(@basic_metadata[:authors].first['email'])
        expect(author.author_orcid).to eq(@basic_metadata[:authors].first['orcid'])
        # Since default affiliation doesn't match ROR, it should have an asterisk appended
        expect(author.affiliation.long_name).to eq("#{@basic_metadata[:authors].first['affiliation']}*")
      end

      it 'allows bad (not blank, but invalid) emails' do
        @basic_metadata = {
          'authors' => [
            {
              'firstName' => 'Wanda',
              'lastName' => 'Jackson',
              'email' => 'grog-to-drink'
            }
          ]
        }.with_indifferent_access

        dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
        @stash_identifier = dp.parse
        resource = @stash_identifier.resources.first
        author = resource.authors.first
        expect(author.author_first_name).to eq(@basic_metadata[:authors].first['firstName'])
        expect(author.author_last_name).to eq(@basic_metadata[:authors].first['lastName'])
        expect(author.author_email).to eq(@basic_metadata[:authors].first['email'])
      end

      it 'reduces emails to one for format of "display name <my@email>"' do
        emails = Array.new(2) { |_i| Faker::Internet.email }
        @basic_metadata = {
          'authors' => [
            {
              'firstName' => 'Wanda',
              'lastName' => 'Jackson',
              'email' => "Crazy Name1 <#{emails.first}>; Crazy Name2 <#{emails.second}>"
            }
          ]
        }.with_indifferent_access

        dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
        @stash_identifier = dp.parse
        resource = @stash_identifier.resources.first
        author = resource.authors.first
        expect(author.author_email).to eq(emails.first)
      end

      it 'reduces emails to one when more are jammed in with commas or semicolons' do
        emails = Array.new(2) { |_i| Faker::Internet.email }
        @basic_metadata = {
          'authors' => [
            {
              'firstName' => 'Wanda',
              'lastName' => 'Jackson',
              'email' => "  #{emails.first}; #{emails.second}" # also adding extra space just for fun
            }
          ]
        }.with_indifferent_access

        dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
        @stash_identifier = dp.parse
        resource = @stash_identifier.resources.first
        author = resource.authors.first
        expect(author.author_email).to eq(emails.first)
      end

      it 'creates the author with a ROR id, matching to an existing affiliation in the database' do
        target_affil = StashDatacite::Affiliation.create(long_name: 'Some Great Institution', ror_id: 'https://ror.org/sgi123')
        @basic_metadata = {
          'authors' => [
            {
              'firstName' => 'Wanda',
              'lastName' => 'Jackson',
              'affiliationROR' => 'https://ror.org/sgi123'
            }
          ]
        }.with_indifferent_access
        dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
        @stash_identifier = dp.parse
        resource = @stash_identifier.resources.first
        author = resource.authors.first

        expect(author.affiliation.id).to eq(target_affil.id)
      end

      it 'creates the author with a ROR id, matching to an existing affiliation in the ROR system' do
        ror_org = create(:ror_org)
        @basic_metadata = {
          'authors' => [
            {
              'firstName' => 'Wanda',
              'lastName' => 'Jackson',
              'affiliationROR' => ror_org.ror_id
            }
          ]
        }.with_indifferent_access
        dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
        @stash_identifier = dp.parse
        resource = @stash_identifier.resources.first
        author = resource.authors.first

        expect(author.affiliation.long_name).to eq(ror_org.name)
      end

      it 'creates the author with an ISNI id, matching to an existing affiliation in the ROR system' do
        ror_org = create(:ror_org)
        isni = "1234 #{Faker::Number.number(digits: 4)} #{Faker::Number.number(digits: 4)} #{Faker::Number.number(digits: 4)}"
        ror_org.update(isni_ids: [isni])

        @basic_metadata = {
          'authors' => [
            {
              'firstName' => 'Wanda',
              'lastName' => 'Jackson',
              'affiliationISNI' => isni.to_s,
              'affiliation' => 'Some Non-matching Name'
            }
          ]
        }.with_indifferent_access
        dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
        @stash_identifier = dp.parse
        resource = @stash_identifier.resources.first
        author = resource.authors.first
        expect(author.affiliation.long_name).to eq(ror_org.name)
      end

      it 'creates the author with an affiliation whose name matches an existing affiliation in the database' do
        target_affil = StashDatacite::Affiliation.create(long_name: 'Some Great Institution', ror_id: 'https://ror.org/sgi123')
        @basic_metadata = {
          'authors' => [
            {
              'firstName' => 'Wanda',
              'lastName' => 'Jackson',
              'affiliation' => 'Some Great Institution'
            }
          ]
        }.with_indifferent_access
        dp = DatasetParser.new(hash: @basic_metadata, id: nil, user: @user)
        @stash_identifier = dp.parse
        resource = @stash_identifier.resources.first
        author = resource.authors.first

        expect(author.affiliation.id).to eq(target_affil.id)
      end

      it 'creates the abstract' do
        resource = @stash_identifier.resources.first
        des = resource.descriptions.first
        expect(des.description).to eq(@basic_metadata[:abstract])
        expect(des.description_type).to eq('abstract')
      end

      it 'creates internal data for the publication metadata' do
        expect(@stash_identifier.publication_issn).to eq('0000-1111')
        expect(@stash_identifier.publication_name).to eq('Some Great Journal')
        expect(@stash_identifier.manuscript_number).to eq('ABC123')
      end

      it 'puts the paymentId on the identifier' do
        expect(@stash_identifier.payment_id). to eq('invoice-123')
        expect(@stash_identifier.payment_type). to eq('stripe')
      end
    end

    describe 'dataset ownership' do
      it 'sets the owner' do
        resource = @stash_identifier.resources.first
        expect(resource.user_id).to eq(@user2.id)
        expect(resource.current_editor_id).to eq(@user2.id)
      end

      it 'sets the owner to an existing user from an ORCID' do
        test_user = StashEngine::User.create(first_name: 'Lena',
                                             last_name: 'Jarre',
                                             email: 'lj123@ucop.edu',
                                             orcid: '1234-5678-0000-1111')
        test_metadata = {
          'title' => 'Visualizing Congestion Control Using Self-Learning Epistemologies',
          'authors' => [{
            'firstName' => 'Wanda',
            'lastName' => 'Jackson',
            'email' => 'wanda.jackson@example.com'
          }],
          'abstract' => 'Cyberneticists agree that concurrent models are fun.',
          'userId' => test_user.orcid
        }.with_indifferent_access

        dp = DatasetParser.new(hash: test_metadata, id: nil, user: @user)
        test_identifier = dp.parse

        resource = test_identifier.resources.first
        expect(resource.user_id).to eq(test_user.id)
      end

      it 'sets the owner to user specified in the metadata with an ORCID' do
        test_orcid = '0000-1111-2222-3333'
        test_metadata = {
          'title' => 'Visualizing Congestion Control Using Self-Learning Epistemologies',
          'authors' => [{
            'firstName' => 'Wanda',
            'lastName' => 'Jackson',
            'email' => 'wanda.jackson@example.com',
            'orcid' => test_orcid
          }],
          'abstract' => 'Cyberneticists agree that concurrent models are fun.',
          'userId' => test_orcid
        }.with_indifferent_access

        dp = DatasetParser.new(hash: test_metadata, id: nil, user: @user)
        test_identifier = dp.parse
        resource = test_identifier.resources.first
        expect(resource.user.first_name).to eq('Wanda')
      end

      it 'defaults ownership to the submitter when the userId is invalid' do
        test_metadata = {
          'title' => 'Visualizing Congestion Control Using Self-Learning Epistemologies',
          'authors' => [{
            'firstName' => 'Wanda',
            'lastName' => 'Jackson',
            'email' => 'wanda.jackson@example.com'
          }],
          'abstract' => 'Cyberneticists agree that concurrent models are fun.',
          'userId' => 'BOGUS-junk'
        }.with_indifferent_access

        dp = DatasetParser.new(hash: test_metadata, id: nil, user: @user)
        test_identifier = dp.parse
        resource = test_identifier.resources.first
        expect(resource.user).to eq(@user)
      end

      it 'errors when the userId is an ORCID, but does not match one set in the author list' do
        test_metadata = {
          'title' => 'Visualizing Congestion Control Using Self-Learning Epistemologies',
          'authors' => [{
            'firstName' => 'Wanda',
            'lastName' => 'Jackson',
            'email' => 'wanda.jackson@example.com',
            'orcid' => '4444-4444-4444-4444'
          }],
          'abstract' => 'Cyberneticists agree that concurrent models are fun.',
          'userId' => '5555-5555-5555-5555'
        }.with_indifferent_access

        dp = DatasetParser.new(hash: test_metadata, id: nil, user: @user)
        expect { dp.parse }.to raise_error(RuntimeError)
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
        mock_tenant!
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

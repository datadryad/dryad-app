require 'db_spec_helper'

module StashEngine
  describe User do
    attr_reader :user

    before(:each) do
      # Mock all the mailers fired by callbacks because these tests don't load everything we need
      allow_any_instance_of(CurationActivity).to receive(:email_author).and_return(true)
      allow_any_instance_of(CurationActivity).to receive(:email_orcid_invitations).and_return(true)
    end

    describe '#from_omniauth_orcid' do

      before(:each) do
        @auth = {
          provider: 'orcid',
          uid: '12345-678',
          info: {
            email: 'lmuckenhaupt@ucop.edu',
            name: 'Morta McWhorter'
          },
          extra: {
            raw_info: {
              first_name: 'Morta',
              last_name:  'McWhorter'
            }
          }
        }.to_ostruct
      end

      it 'creates a user' do
        user = User.from_omniauth_orcid(auth_hash: @auth, emails: ['lmuckenhaupt@ucop.edu'])
        expect(user).to be_a(User)
        expect(user).to be_persisted
        expect(user.orcid).to eq('12345-678')
        expect(user.first_name).to eq('Morta')
        expect(user.last_name).to eq('McWhorter')
        expect(user.email).to eq('lmuckenhaupt@ucop.edu')
      end

      it "finds by email and updates a user's orcid" do
        # this creates the user, as tested above
        User.from_omniauth_orcid(auth_hash: @auth, emails: ['lmuckenhaupt@ucop.edu'])
        @auth[:uid] = '987-654-321'
        user2 = User.from_omniauth_orcid(auth_hash: @auth, emails: ['lmuckenhaupt@ucop.edu'])
        expect(user2.orcid).to eq('987-654-321')
      end

    end

    describe '#tenant' do
      it 'finds the tenant' do
        tenant = instance_double(Tenant)
        allow(Tenant).to receive(:find).with('ucop').and_return(tenant)
        user = User.create(tenant_id: 'ucop')
        expect(user.tenant).to eq(tenant)
      end
    end

    describe '#latest_completed_resource_per_identifier' do
      attr_reader :user

      before(:each) do
        @user = User.create(
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          tenant_id: 'ucop'
        )
      end

      it 'finds the user\'s resources' do
        resources = Array.new(5) do |index|
          resource = Resource.create(user_id: user.id, skip_emails: true)
          resource.current_state = 'submitted'
          resource.ensure_identifier("10.123/#{index}")
          resource
        end
        latest = user.latest_completed_resource_per_identifier
        expect(latest).to contain_exactly(*resources)
      end

      it 'ignores "in progress" resources' do
        in_progress = []
        other = []
        %w[submitted processing].each_with_index do |state, index|
          doi_value = "10.123/#{index}"
          res1 = Resource.create(user_id: user.id, skip_emails: true)
          res1.ensure_identifier(doi_value)
          res1.current_state = 'in_progress'
          in_progress << res1
          res2 = Resource.create(user_id: user.id, skip_emails: true)
          res2.ensure_identifier(doi_value)
          res2.current_state = state
          other << res2
        end
        latest = user.latest_completed_resource_per_identifier
        expect(latest).to contain_exactly(*other)
        in_progress.each do |res|
          expect(latest).not_to include(res)
        end
      end

      it 'finds only the latest for each identifier' do
        resources = Array.new(5) do |_|
          doi_value = '10.123/1234'
          resource = Resource.create(user_id: user.id, skip_emails: true)
          resource.current_state = 'submitted'
          resource.ensure_identifier(doi_value)
          resource
        end
        latest = user.latest_completed_resource_per_identifier
        expect(latest).to contain_exactly(resources.last)
      end

      it 'returns a user\'s name' do
        user = User.create(first_name: 'Johann', last_name: 'Jones')
        expect(user.name).to eq('Johann Jones')
        user2 = User.create(first_name: 'Bob', last_name: nil)
        expect(user2.name).to eq('Bob')
      end

      it 'returns if user is a superuser' do
        user = User.create(role: 'superuser')
        expect(user.superuser?).to be_truthy
        user2 = User.create(role: 'user')
        expect(user2.superuser?).to be_falsey
      end
    end

    describe 'find_by_orcid_or_emails' do
      before(:each) do
        User.create(
          email: 'lmuckenhaupt@ucop.edu'
        )
        User.create(
          orcid: '12345678'
        )
        User.create(
          email: 'grover@example.org',
          orcid: '87654321'
        )
      end

      it 'finds by the orcid only' do
        users = User.find_by_orcid_or_emails(orcid: '12345678', emails: [])
        expect(users.count).to eq(1)
      end

      it 'finds by emails only' do
        users = User.find_by_orcid_or_emails(orcid: nil, emails: ['lmuckenhaupt@ucop.edu', 'grover@example.org'])
        expect(users.count).to eq(2)
      end

      it 'ignores nils and blanks in emails' do
        users = User.find_by_orcid_or_emails(orcid: nil, emails: nil)
        expect(users.count).to eq(0)

        users = User.find_by_orcid_or_emails(orcid: nil, emails: [nil, nil])
        expect(users.count).to eq(0)

        users = User.find_by_orcid_or_emails(orcid: nil, emails: ['', ''])
        expect(users.count).to eq(0)
      end

      it 'combines results for orcids and emails' do
        users = User.find_by_orcid_or_emails(orcid: '12345678', emails: ['lmuckenhaupt@ucop.edu', 'grover@example.org'])
        expect(users.count).to eq(3)
      end
    end

    describe 'migration tokens actions' do
      before(:each) do
        @user = User.create(
          migration_token: '123456'
        )
      end

      it 'detects migration is not complete' do
        expect(user.migration_complete?).to be false
      end

      it 'migration_complete! sets and detects a migration_complete?' do
        user.migration_complete!
        expect(user.migration_complete?).to be true
      end

      it "set_migration_token doesn't set a new token if one exists" do
        user.set_migration_token
        expect(user.migration_token).to eq('123456')
      end

      it "sets a migration token when one doesn't exist" do
        user.migration_token = nil
        user.set_migration_token
        expect(user.migration_token.length).to eq(6)
      end
    end
  end
end

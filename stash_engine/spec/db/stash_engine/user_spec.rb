require 'db_spec_helper'

module StashEngine
  describe User do
    attr_reader :user

    describe '#from_omniauth' do
      it 'creates a user' do
        auth = {
          provider: 'google_oauth2',
          uid: 'lmuckenhaupt-ucop@ucop.edu',
          info: {
            email: 'lmuckenhaupt@ucop.edu',
            name: 'Lisa Muckenhaupt'
          },
          credentials: {
            token: '1234567890'
          }
        }.to_ostruct
        user = User.from_omniauth(auth, 'ucop', '1234-5678-9012-3456')
        expect(user).to be_a(User)
        expect(user).to be_persisted
        expect(user.uid).to eq('lmuckenhaupt-ucop@ucop.edu')
        expect(user.first_name).to eq('Lisa')
        expect(user.last_name).to eq('Muckenhaupt')
        expect(user.email).to eq('lmuckenhaupt@ucop.edu')
        expect(user.provider).to eq('google_oauth2')
        expect(user.tenant_id).to eq('ucop')
        expect(user.oauth_token).to eq('1234567890')
        expect(user.orcid).to eq('1234-5678-9012-3456')
      end
    end

    describe '#tenant' do
      it 'finds the tenant' do
        tenant = instance_double(Tenant)
        allow(Tenant).to receive(:find).with('ucop').and_return(tenant)
        user = User.create(uid: 'lmuckenhaupt-ucop@ucop.edu', tenant_id: 'ucop')
        expect(user.tenant).to eq(tenant)
      end
    end

    describe '#latest_completed_resource_per_identifier' do
      attr_reader :user

      before(:each) do
        @user = User.create(
          uid: 'lmuckenhaupt-ucop@ucop.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          provider: 'developer',
          tenant_id: 'ucop'
        )
      end

      it 'finds the user\'s resources' do
        resources = Array.new(5) do |index|
          resource = Resource.create(user_id: user.id)
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
          res1 = Resource.create(user_id: user.id)
          res1.ensure_identifier(doi_value)
          res1.current_state = 'in_progress'
          in_progress << res1
          res2 = Resource.create(user_id: user.id)
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
          resource = Resource.create(user_id: user.id)
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
  end
end

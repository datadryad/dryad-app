module StashEngine
  describe User, type: :model do
    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!
      # Mock all the mailers fired by callbacks because these tests don't load everything we need
      allow_any_instance_of(CurationActivity).to receive(:email_status_change_notices).and_return(true)
      allow_any_instance_of(CurationActivity).to receive(:email_orcid_invitations).and_return(true)
      @user = create(:user)
    end

    context 'associations' do

      it { is_expected.to have_many(:resources) }

    end

    describe 'name should return "[first_name] [last_name]"' do

      it 'returns the right value when first and last name are both available' do
        expect(@user.name).to eql("#{@user.first_name} #{@user.last_name}")
      end

      it 'returns the first name if no last name is available' do
        @user.last_name = nil
        expect(@user.name).to eql(@user.first_name)
      end

      it 'returns the last name if no first name is available' do
        @user.first_name = nil
        expect(@user.name).to eql(@user.last_name)
      end

      it 'returns an empty string if no first or last name is available' do
        @user.first_name = nil
        @user.last_name = nil
        expect(@user.name).to eql('')
      end

    end

    context :affiliation do
      before(:each) do
        # I don't see any factories here, so just creating a resource manually
        @user = create(:user,
                       first_name: 'Lisa',
                       last_name: 'Muckenhaupt',
                       email: 'lmuckenhaupt@ucop.edu',
                       tenant_id: 'ucop')
        @affiliation = create(:affiliation,
                              short_name: 'Testing',
                              abbreviation: 'TEST',
                              ror_id: '1234')
      end

      it 'can be assigned' do
        expect(@user.affiliation).to eql(nil)
        @user.affiliation = @affiliation
        expect(@user.affiliation).to eql(@affiliation)
      end
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
              last_name: 'McWhorter'
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

      before(:each) do
        @user = create(:user,
                       first_name: 'Lisa',
                       last_name: 'Muckenhaupt',
                       email: 'lmuckenhaupt@ucop.edu',
                       tenant_id: 'ucop')
      end

      it 'finds the user\'s resources' do
        resources = Array.new(5) do |index|
          ident = create(:identifier, identifier: "10.123/#{index}")
          resource = create(:resource, user_id: @user.id, skip_emails: true, identifier: ident)
          resource.current_state = 'submitted'
          resource
        end
        latest = @user.latest_completed_resource_per_identifier
        expect(latest).to contain_exactly(*resources)
      end

      it 'ignores "in progress" resources' do
        in_progress = []
        other = []
        %w[submitted processing].each_with_index do |state, index|
          ident = create(:identifier, identifier: "10.123/#{index}")
          res1 = create(:resource, user_id: @user.id, skip_emails: true, identifier: ident)
          res1.current_state = 'in_progress'
          in_progress << res1
          res2 = create(:resource, user_id: @user.id, skip_emails: true, identifier: ident)
          res2.current_state = state
          other << res2
        end
        latest = @user.latest_completed_resource_per_identifier
        expect(latest).to contain_exactly(*other)
        in_progress.each do |res|
          expect(latest).not_to include(res)
        end
      end

      # TODO: fix this intermittent failing test #806
      xit 'finds only the latest for each identifier' do
        user = create(:user)
        ident = create(:identifier, identifier: '10.123/1234')
        resources = Array.new(5) do |_|
          resource = create(:resource, user: user, skip_emails: true, identifier: ident)
          resource.current_state = 'submitted'
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

      it 'returns correct role information more generous roles contain lesser roles)' do
        user = User.create(role: 'superuser')
        expect(user.superuser?).to be_truthy
        expect(user.curator?).to be_truthy
        expect(user.limited_curator?).to be_truthy

        user2 = User.create(role: 'curator')
        expect(user2.superuser?).to be_falsey
        expect(user2.curator?).to be_truthy
        expect(user2.limited_curator?).to be_truthy

        user3 = User.create(role: 'user')
        expect(user3.superuser?).to be_falsey
        expect(user3.curator?).to be_falsey
        expect(user3.limited_curator?).to be_falsey

        user4 = User.create(role: 'limited_curator')
        expect(user4.superuser?).to be_falsey
        expect(user4.curator?).to be_falsey
        expect(user4.limited_curator?).to be_truthy
      end
    end

    describe 'find_by_orcid_or_emails' do
      before(:each) do
        create(:user,
               email: 'lmuckenhaupt@ucop.edu')
        create(:user,
               orcid: '12345678')
        create(:user,
               email: 'grover@example.org',
               orcid: '87654321')
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

    describe 'merge_user!(other_user:)' do
      before(:each) do
        # create users1 and user2 to be merged and user3 to be left alone

        @user1 = create(:user, first_name: 'Gloriana', last_name: 'McSweeney', email: 'gmc@example.com',
                               tenant_id: 'exemplia', role: 'user', orcid: '1098-415-1212')
        @identifier1 = create(:identifier)
        @resource1 = create(:resource, identifier_id: @identifier1.id, user_id: @user1.id, current_editor_id: @user1.id)
        @curation_activity1 = create(:curation_activity, resource: @resource1, user_id: @user1.id)
        @resource_state1 = create(:resource_state, user_id: @user1.id, resource_state: 'submitted', resource_id: @resource1.id)

        @user2 = create(:user, first_name: 'Henry', last_name: 'Hale', email: 'hh@example.com',
                               tenant_id: 'ucop', role: 'admin', orcid: '1099-9999-9999')
        @identifier2 = create(:identifier)
        @resource2 = create(:resource, identifier_id: @identifier2.id, user_id: @user2.id, current_editor_id: @user2.id)
        @curation_activity2 = create(:curation_activity, resource: @resource2, user_id: @user2.id)
        @resource_state2 = create(:resource_state, user_id: @user2.id, resource_state: 'submitted', resource_id: @resource2.id)

        @user3 = create(:user, first_name: 'Rodrigo', last_name: 'Sandoval', email: 'rjsand@example.com',
                               tenant_id: 'exemplia', role: 'superuser', orcid: '1234-9999-9999')
        @identifier3 = create(:identifier)
        @resource3 = create(:resource, identifier_id: @identifier3.id, user_id: @user3.id, current_editor_id: @user3.id)
        @curation_activity3 = create(:curation_activity, resource: @resource3, user_id: @user3.id)
        @resource_state3 = create(:resource_state, user_id: @user3.id, resource_state: 'submitted', resource_id: @resource3.id)

        @mock_idgen = double('idgen')
        allow(@mock_idgen).to receive('update_identifier_metadata!'.intern).and_raise('submitted DOI')
        allow(Stash::Doi::IdGen).to receive(:make_instance).and_return(@mock_idgen)
      end

      it 'moves the dependendent resources from user2 to user1' do
        @user1.merge_user!(other_user: @user2)
        @user1.reload
        @user2.reload
        @user3.reload

        expect(@user1.resources.count).to eq(2) # this user owns both for user 1 & 2
        expect(@user2.resources.count).to eq(0) # this user owns none of the resources
        expect(@user3.resources.count).to eq(1) # this user still only owns his own resource and it hasn't changed
      end

      it 'moves the dependendent resource states from user2 to user1 and leaves others alone' do
        @user1.merge_user!(other_user: @user2)
        @user1.reload
        @user2.reload
        @user3.reload

        # I'm not sure why we have a user_id on this at all, since isn't it always the same as the resource.user_id?
        expect(@user1.resources.first.resource_states.first.user_id).to eq(@user1.id)
        expect(@user1.resources.second.resource_states.first.user_id).to eq(@user1.id)
        expect(@user3.resources.first.resource_states.first.user_id).to eq(@user3.id)
      end

      it 'moves the dependendent curation_activities from user2 to user1 and leaves others alone' do
        @user1.merge_user!(other_user: @user2)
        @user1.reload
        @user2.reload
        @user3.reload

        expect(@user1.resources.first.curation_activities.first.user_id).to eq(@user1.id)
        expect(@user1.resources.second.curation_activities.first.user_id).to eq(@user1.id)
        expect(@user3.resources.first.curation_activities.first.user_id).to eq(@user3.id)
      end

      it 'sets the current editor ids correctly for the move' do
        @user1.merge_user!(other_user: @user2)
        @user1.reload
        @user2.reload
        @user3.reload

        expect(@user1.resources.first.current_editor_id).to eq(@user1.id)
        expect(@user1.resources.second.current_editor_id).to eq(@user1.id)
        expect(@user3.resources.first.current_editor_id).to eq(@user3.id)
      end

      it 'overrides settings for the user' do
        @user1.merge_user!(other_user: @user2)
        @user1.reload
        @user2.reload
        @user3.reload

        expect(@user1.first_name).to eq(@user2.first_name)
        expect(@user1.last_name).to eq(@user2.last_name)
        expect(@user1.email).to eq(@user2.email)
        expect(@user1.tenant_id).to eq(@user2.tenant_id)
        expect(@user1.last_login).to eq(@user2.last_login)
        expect(@user1.orcid).to eq(@user2.orcid)
      end

      it "allows keeping settings if something isn't set" do

        # a grab bag of some things missing from @user2, so retained from @user1
        @user2 = create(:user, first_name: nil, last_name: 'Hale', email: nil,
                               tenant_id: nil, role: 'admin', orcid: '1099-9999-9999')

        @user1.merge_user!(other_user: @user2)
        @user1.reload
        @user2.reload

        expect(@user1.first_name).to eq(@user1.first_name)
        expect(@user1.last_name).to eq(@user2.last_name)
        expect(@user1.email).to eq(@user1.email)
        expect(@user1.tenant_id).to eq(@user1.tenant_id)
        expect(@user1.last_login).to eq(@user2.last_login)
        expect(@user1.orcid).to eq(@user2.orcid)
      end

    end
  end
end

require_relative '../stash_api/helpers'
module StashDatacite
  RSpec.describe SubjectsController, type: :request, skip: 'figure out authentication' do
    before(:each) do
      @user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )

      @resource = create(:resource, user_id: @user.id)

      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    describe 'create' do
      let(:params_hash) do
        {
          resource_id: @resource.id,
          subject: ' foo, , bar ,baz '
        }
      end

      it 'strips subject strings and removes blanks' do
        # when
        post '/stash_datacite/subjects/create', params: params_hash, headers: default_authenticated_headers, as: :json

        # then
        subjects = StashDatacite::Subject.all

        expect(subjects.map(&:subject)).to eq(%w[foo bar baz])
      end
    end
  end
end

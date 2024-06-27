require_relative '../stash_api/helpers'

module StashDatacite
  RSpec.describe SubjectsController, type: :request do
    before(:each) do
      @user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )

      @resource = create(:resource, user_id: @user.id, subjects: [])
      allow_any_instance_of(SubjectsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe 'create' do
      let(:params_hash) { { resource_id: @resource.id, subject: ' foo, , bar ,bz , ;tag;,[this1., tag, ' } }

      # removes starting and ending punctuation and spaces
      # removes duplicates
      # removes empty tags
      # does NOT remove punctuation from inside of tag
      # does not remove numbers
      it 'strips subject strings and removes blanks' do
        post '/stash_datacite/subjects/create', params: params_hash, headers: default_authenticated_headers, as: :json

        expected_array = %w[foo bar bz tag this1]
        json_response = JSON.parse(response.body)
        expect(json_response.map { |a| a['subject'] } & expected_array).to match_array(expected_array)
      end
    end
  end
end

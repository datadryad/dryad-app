# We have no real way to test this directly in the UI since setting a related identifier to hidden can't be done in the
# UI and testing the UI runs in a different process/database which is difficult to manipulate manually.
module StashDatacite
  RSpec.describe AffiliationsController, type: :request do

    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = create(:resource, user_id: user.id)
      @related_identifier = create(:related_identifier, resource_id: @resource.id, work_type: 'article')
    end

    describe 'non-hidden related IDs' do
      it 'renders a non-hidden related work' do
        response_code = get "/stash_datacite/related_identifiers/show.js?resource_id=#{@resource.id}", xhr: true
        expect(response_code).to eq(200)

        body = response.body
        expect(body).to include('Article')
        expect(body).to include(@related_identifier.related_identifier)
      end

      it 'hides a hidden related work' do
        @related_identifier.update(hidden: true)
        response_code = get "/stash_datacite/related_identifiers/show.js?resource_id=#{@resource.id}", xhr: true
        expect(response_code).to eq(200)

        body = response.body
        expect(body).not_to include('Article')
        expect(body).not_to include(@related_identifier.related_identifier)
      end

    end
  end
end

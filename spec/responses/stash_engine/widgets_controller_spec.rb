require 'rails_helper'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe WidgetsController, type: :request do

    include MerrittHelper
    include DatasetHelper
    include Mocks::Datacite
    include Mocks::Repository
    include Mocks::RSolr
    include Mocks::Ror
    include Mocks::Stripe

    before(:each) do
      # kind of crazy to mock all this, but creating the curation activity of published triggers all sorts of stuff
      mock_repository!
      mock_solr!
      mock_ror!
      mock_datacite!
      mock_stripe!
      @user = create(:user, role: 'superuser')
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, identifier: @identifier, user_id: @user.id, tenant_id: @user.tenant_id)
    end

    describe '#banner_for_pub' do
      it 'has a banner when valid data and format supplied for a published dataset' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'published')
        get '/widgets/bannerForPub', { 'pubId' => @identifier.to_s, referrer: 'grog' }
        expect(response).to have_http_status(:ok)
      end

      it 'has a banner when valid data and format supplied for an embargoed dataset' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'embargoed')
        get '/widgets/bannerForPub', { 'pubId' => @identifier.to_s, referrer: 'grog' }
        expect(response).to have_http_status(:ok)
      end

      it 'has a banner when valid data and format supplied using a valid pubmedID' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'embargoed')
        my_datum = create(:internal_datum, identifier_id: @identifier.id, data_type: 'pubmedID', value: Faker::Number.number(8))
        get '/widgets/bannerForPub', { 'pubId' => "pmid:#{my_datum.value}", referrer: 'grog' }
        expect(response).to have_http_status(:ok)
      end
    end

    describe '#data_package_for_pub' do

    end
  end
end
# rubocop:enable Metrics/BlockLength
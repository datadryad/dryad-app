# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe WidgetsController, type: :request do

    include MerrittHelper
    include DatasetHelper
    include Mocks::CurationActivity
    include Mocks::Datacite
    include Mocks::Repository
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe

    before(:each) do
      # kind of crazy to mock all this, but creating identifiers and the curation activity of published triggers all sorts of stuff
      mock_repository!
      mock_salesforce!
      mock_solr!
      mock_datacite_and_idgen!
      mock_stripe!
      ignore_zenodo!
      @user = create(:user, role: 'superuser')
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, identifier: @identifier, user_id: @user.id, tenant_id: @user.tenant_id)
      @publication_doi = create(:related_identifier, :publication_doi, resource: @resource)
      @pmid = create(:internal_datum, identifier_id: @identifier.id, data_type: 'pubmedID', value: Faker::Number.number(digits: 8))
    end

    describe '#banner_for_pub' do
      it 'has a banner when valid data and format supplied for a published dataset' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'published')
        get '/widgets/bannerForPub',
            params: { 'pubId' => "doi:#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:ok)
      end

      it 'has a banner when valid data and format supplied for an embargoed dataset' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'embargoed')
        get '/widgets/bannerForPub',
            params: { 'pubId' => "doi:#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:ok)
      end

      it 'has a banner when valid data and format supplied using a valid pubmedID' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'embargoed')
        get '/widgets/bannerForPub',
            params: { 'pubId' => "pmid:#{@pmid.value}", referrer: 'grog' }
        expect(response).to have_http_status(:ok)
      end

      it 'returns blank image and 404 status with it when pubId or referrer not supplied' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'embargoed')

        get '/widgets/bannerForPub', params: { 'pubId' => "doi:#{@publication_doi.related_identifier}" }
        expect(response).to have_http_status(:not_found)

        get '/widgets/bannerForPub', params: { referrer: 'grog' }
        expect(response).to have_http_status(:not_found)
      end

      it 'accepts the many different valid URLs for DOIs' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'published')

        get '/widgets/bannerForPub',
            params: { 'pubId' => "https://doi.org/#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:ok)

        get '/widgets/bannerForPub',
            params: { 'pubId' => "http://doi.org/#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:ok)

        get '/widgets/bannerForPub',
            params: { 'pubId' => "http://dx.doi.org/#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:ok)

        get '/widgets/bannerForPub',
            params: { 'pubId' => "https://dx.doi.org/#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 with badly formatted IDs' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'published')
        get '/widgets/bannerForPub',
            params: { 'pubId' => "dog:#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:not_found)

        get '/widgets/bannerForPub',
            params: { 'pubId' => "http://drx.doi.org/#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:not_found)
      end

      it "rejects DOIs that don't exist in our system" do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'published')
        get '/widgets/bannerForPub',
            params: { 'pubId' => 'doi:10.5072/aardvark.385722', referrer: 'grog' }
        expect(response).to have_http_status(:not_found)
      end

      it "rejects DOIs that haven't been made public from curation" do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'curation')
        get '/widgets/bannerForPub', params: { 'pubId' => "doi:#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(:not_found)
      end

      it 'rejects invalid pubmedIDs for our system' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'embargoed')
        get '/widgets/bannerForPub', params: { 'pubId' => "pmid:#{@pmid.value}11", referrer: 'grog' }
        expect(response).to have_http_status(:not_found)
      end

      it 'rejects pubmedIDs that are not public in our system' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'curation')
        get '/widgets/bannerForPub', params: { 'pubId' => "pmid:#{@pmid.value}", referrer: 'grog' }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe '#data_package_for_pub' do
      # the data_package_for_pub uses all the same checks that the image widget does, it simply returns something else than an image
      it 'redirects to landing page for published dataset by DOI' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'published')
        get '/widgets/dataPackageForPub', params: { 'pubId' => "doi:#{@publication_doi.related_identifier}", referrer: 'grog' }
        expect(response).to have_http_status(302)
        expect(response.headers['location']).to end_with(@identifier.to_s)
      end

      it 'redirects to the landing page for a pubmed id' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'embargoed')
        get '/widgets/dataPackageForPub', params: { 'pubId' => "pmid:#{@pmid.value}", referrer: 'grog' }
        expect(response).to have_http_status(302)
        expect(response.headers['location']).to end_with(@identifier.to_s)
      end

      it 'unavailable shows page that shows not-available' do
        create(:curation_activity, user_id: @user.id, resource_id: @resource.id, status: 'published')
        get '/widgets/dataPackageForPub', params: { referrer: 'grog' }
        expect(response).to have_http_status(404)
      end

      # note, all the formatting, identifier lookup and other functions are shared across the page and have already been
      # tested in the banner_for_pub action, so no reason to re-test them here since they are the same prerequisites
    end
  end
end
# rubocop:enable

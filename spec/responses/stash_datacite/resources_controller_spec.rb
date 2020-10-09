module StashDatacite
  RSpec.describe ResourcesController, type: :request do

    # include MerrittHelper
    # include DatasetHelper
    include DatabaseHelper
    # include Mocks::CurationActivity
    # include Mocks::Datacite
    include Mocks::Repository
    # include Mocks::RSolr
    include Mocks::Ror
    include Mocks::Stripe
    # include Mocks::Tenant

    before(:each) do
      # kind of crazy to mock all this, but creating identifiers and the curation activity of published triggers all sorts of stuff
      mock_repository!
      # mock_solr!
      mock_ror!
      # mock_datacite!
      mock_stripe!
      # mock_tenant!
      # ignore_zenodo!
      # neuter_curation_callbacks!

      # below will create @identifier, @resource, @user and the basic required things for an initial version of a dataset
      create_basic_dataset! # makes @user, @identifier, @resource with file uploads

      # HACK: in session because requests specs don't allow session in rails unless you want to request the full login nightmare first
      # https://github.com/rails/rails/issues/23386#issuecomment-178013357
      allow_any_instance_of(StashDatacite::ResourcesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe 'Review actions' do
      it 'creates basic dataset metadata for review' do
        get StashDatacite::Engine.routes.url_helpers.resources_review_path(id: @resource.id, format: 'js'), xhr: true
        expect(response.body).to include(@resource.title)
      end

    end
  end
end

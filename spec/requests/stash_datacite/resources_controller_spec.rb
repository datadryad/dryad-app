module StashDatacite
  RSpec.describe ResourcesController, type: :request do

    include DatabaseHelper
    include Mocks::Repository
    include Mocks::Salesforce
    include Mocks::Stripe

    before(:each) do
      mock_repository!
      mock_salesforce!
      mock_stripe!

      # below will create @identifier, @resource, @user and the basic required things for an initial version of a dataset
      create_basic_dataset! # makes @user, @identifier, @resource with file uploads
      @resource.generic_files.each { |f| f.update(url: 'http://example.com') } # bypasses S3 file validation by using URL instead

      # HACK: in session because requests specs don't allow session in rails unless you want to request the full login nightmare first
      # https://github.com/rails/rails/issues/23386#issuecomment-178013357
      allow_any_instance_of(StashDatacite::ResourcesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe 'Review AJAX' do
      it 'creates basic dataset metadata for review' do
        get resources_review_path(id: @resource.id, format: 'js'), xhr: true
        expect(response.body).to include(@resource.title)
      end

      it 'shows files for Merritt' do
        @upload = create(:data_file,
                         resource: @resource,
                         file_state: 'created',
                         url: 'http://example.com',
                         status_code: 200)

        get resources_review_path(id: @resource.id, format: 'js'), xhr: true
        expect(response.body).to include(@upload.upload_file_name)
      end

      it 'outputs files for Zenodo' do
        @upload = create(:software_file,
                         resource: @resource,
                         file_state: 'created',
                         url: 'http://example.com',
                         status_code: 200)

        get resources_review_path(id: @resource.id, format: 'js'), xhr: true
        expect(response.body).to include(@upload.upload_file_name)
      end

    end
  end
end

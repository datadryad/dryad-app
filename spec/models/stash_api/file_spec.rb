require 'byebug'

module StashApi
  RSpec.describe File do
    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!

      # put the setup before the mocks (I think) and then metadata call at the end
      identifier = create(:identifier)
      user = create(:user)
      resource = create(:resource, identifier_id: identifier.id, user_id: user.id)
      create(:resource_state, resource: resource, user: user)
      create(:version, resource_id: resource.id)

      @data_file = create(:data_file, resource_id: resource.id)
      display_file = StashApi::File.new(file_id: @data_file.id)

      generic_path = double('generic_path')
      allow(generic_path).to receive(:dataset_path).and_return('dataset_foobar_path')
      allow(generic_path).to receive(:dataset_versions_path).and_return('dataset_versions_foobar_path')
      allow(generic_path).to receive(:version_path).and_return('version_foobar_path')
      allow(generic_path).to receive(:file_path).and_return('file_foobar_path')
      allow(generic_path).to receive(:version_files_path).and_return('version_files_foobar_path')
      allow(generic_path).to receive(:download_file_path).and_return('file_download_foobar_path')

      allow_any_instance_of(Dataset).to receive(:api_url_helper).and_return(generic_path)
      allow_any_instance_of(File).to receive(:api_url_helper).and_return(generic_path)
      allow_any_instance_of(Version).to receive(:api_url_helper).and_return(generic_path)

      @metadata = display_file.metadata
    end

    describe :file_display do
      it 'has correct path' do
        expect(@metadata[:path]).to eq(@data_file.upload_file_name)
      end

      it 'has correct size' do
        expect(@metadata[:size]).to eq(@data_file.upload_file_size)
      end

      it 'has the correct mimeType' do
        expect(@metadata[:mimeType]).to eq(@data_file.upload_content_type)
      end

      it 'has the correct status' do
        expect(@metadata[:status]).to eq(@data_file.file_state)
      end

      it 'has a url' do
        expect(@metadata[:url]).to eq(@data_file.url)
      end

      it 'shows the correct digest' do
        expect(@metadata[:digest]).to eq(@data_file.digest)
      end

      it 'shows the correct digestType' do
        expect(@metadata[:digestType]).to eq(@data_file.digest_type)
      end

      it 'shows the correct description' do
        expect(@metadata[:description]).to eq(@data_file.description)
      end
    end

  end
end

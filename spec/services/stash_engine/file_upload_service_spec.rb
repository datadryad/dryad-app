module StashEngine
  describe FileUploadService do
    include Mocks::Aws

    let(:resource) { create(:resource, created_at: 1.minute.ago) }
    let(:file_params) do
      {
        download_filename: File.basename(Faker::File.file_name),
        upload_file_name: "#{Faker::Internet.uuid}.txt",
        upload_content_type: 'text/plain',
        upload_file_size: Faker::Number.between(from: 1, to: 100_000_000)
      }
    end
    let(:url_file_params) do
      {
        download_filename: File.basename(Faker::File.file_name),
        upload_file_name: "#{Faker::Internet.uuid}.csv",
        upload_content_type: 'text/csv',
        upload_file_size: Faker::Number.between(from: 1, to: 100_000_000),
        url: Faker::Internet.url,
        status_code: 200
      }
    end

    describe '#initialize' do
      it 'sets file params' do
        instance = described_class.new(resource: resource, file_params: file_params.clone)
        expect(instance.file).to have_attributes(file_params)
        expect(instance.file).to have_attributes({ resource_id: resource.id, file_state: 'created' })
      end

      it 'sets url file params' do
        instance = described_class.new(resource: resource, file_params: url_file_params.clone)
        expect(instance.file).to have_attributes(url_file_params)
        expect(instance.file).to have_attributes({ resource_id: resource.id, file_state: 'created' })
      end
    end

    subject(:service) { described_class.new(resource: resource, file_params: file_params) }
    subject(:url_service) { described_class.new(resource: resource, file_params: url_file_params) }

    describe '#trigger_checks' do
      it 'triggers the correct checks for the txt file' do
        service.save

        expect(service.file.frictionless_report).to eq(nil)
        expect(service.file.sensitive_data_report.status).to eq('checking')
      end

      it 'triggers the correct checks for the csv file' do
        url_service.save

        expect(url_service.file.frictionless_report.status).to eq('error')
        expect(url_service.file.sensitive_data_report.status).to eq('checking')
      end

      it 'triggers no checks for a non-matching file' do
        image_params = { download_filename: 'test.png', upload_file_name: "#{Faker::Internet.uuid}.png", upload_content_type: 'image/png',
                         upload_file_size: Faker::Number.between(from: 1, to: 100_000_000) }
        instance = described_class.new(resource: resource, file_params: image_params)
        expect(instance.file.frictionless_report).to eq(nil)
        expect(instance.file.sensitive_data_report).to eq(nil)
      end
    end
  end
end

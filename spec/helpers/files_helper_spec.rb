require 'rails_helper'

RSpec.describe FilesHelper, type: :helper do
  describe '#download_file_name_link' do
    let(:file) { create(:generic_file, id: 123, upload_file_name: 'Test Document.pdf', file_deleted_at: nil) }
    # let(:params) { { file_id: 123 } }
    let(:shortened_name) { 'Test Document.pdf' }

    before do
      allow(file.upload_file_name).to receive(:ellipsisize).with(200).and_return(shortened_name)
      allow(helper).to receive(:download_stream_path).with(params).and_return('/download/123')
    end

    context 'when file is not deleted' do
      it 'returns a download link with the file name' do
        result = helper.download_file_name_link(file, params)

        expect(result).to include('href="/download/123"')
        expect(result).to include('Test Document.pdf')
        expect(result).to include('fas fa-download')
      end
    end

    context 'when file is deleted' do
      let(:file) { create(:generic_file, id: 123, upload_file_name: 'Test Document.pdf', file_deleted_at: Time.current) }

      it 'returns a span with a cancel icon and file name' do
        result = helper.download_file_name_link(file, params)

        expect(result).to include('fas fa-cancel')
        expect(result).to include('<span>')
        expect(result).to include('Test Document.pdf')
        expect(result).to_not include('href=')
      end
    end
  end
end

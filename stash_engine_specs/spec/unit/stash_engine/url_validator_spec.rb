require 'spec_helper'
require 'webmock/rspec'

module StashEngine
  describe UrlValidator do

    attr_reader :uv

    before(:each) do
      WebMock.disable_net_connect!
      @uv = UrlValidator.new(url: 'http://www.blahstackfood.com')
    end

    it 'retrieves a url' do
      stub_request(:any, 'http://www.blahstackfood.com')
      success = uv.validate
      # [ uv.mime_type, uv.size, uv.url, uv.status_code, uv.redirected_to, uv.timed_out?, uv.redirected?, uv.correctly_formatted_url? ]
      expect(success).to eq(true)
      expect(uv.status_code).to eq(200)
    end

    describe :filename_from_content_disposition do
      it 'returns nil when no filename present' do
        disposition = 'attachment'
        filename = uv.filename_from_content_disposition(disposition)
        expect(filename).to be_nil
      end

      it 'extracts a filename' do
        disposition = 'attachment; filename="filename.jpg"'
        filename = uv.filename_from_content_disposition(disposition)
        expect(filename).to eq('filename.jpg')
      end

      it 'handles rfc5646 escapes' do
        disposition = "attachment; filename*=UTF-8'de-CH-1901'%F0%9F%A6%84.txt"
        filename = uv.filename_from_content_disposition(disposition)
        # expect(filename).to eq("\u{1F984}.txt")
        expect(filename).to eq('🦄.txt')
      end

    end

  end
end

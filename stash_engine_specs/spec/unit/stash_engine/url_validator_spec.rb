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

    describe :validate do

      attr_reader :client

      before(:each) do
        @client = instance_double(HTTPClient)
        allow(HTTPClient).to receive(:new).and_return(client)

        ssl_config = instance_double(HTTPClient::SSLConfig)
        allow(ssl_config).to receive(:verify_mode=)
        allow(client).to receive(:ssl_config).and_return(ssl_config)

        messages = [
          :redirect_uri_callback=,
          :connect_timeout=,
          :send_timeout=,
          :receive_timeout=,
          :keep_alive_timeout=
        ].map { |k| [k, nil] }.to_h

        allow(client).to receive_messages(messages)
      end

      after(:each) do
        allow(HTTPClient).to receive(:new).and_call_original
      end

      it 'returns false/400 for a bad url' do
        uv = UrlValidator.new(url: 'I am not a URL')
        expect(uv.validate).to eq(false)
        expect(uv.status_code).to eq(400)
      end

      it 'returns false/408 for a timeout' do
        expect(client).to receive(:head).and_raise(HTTPClient::TimeoutError)
        expect(uv.validate).to eq(false)
        expect(uv.timed_out?).to eq(true)
        expect(uv.status_code).to eq(408)
      end

      it 'returns 409 for too many retries' do
        expect(client).to receive(:head).exactly(3).times.and_raise(Errno::ECONNREFUSED)
        expect(uv.validate).to eq(false)
        expect(uv.status_code).to eq(499)
      end

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

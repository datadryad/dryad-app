require 'webmock/rspec'

module StashEngine
  describe UrlValidator do
    attr_reader :uv

    before(:each) do
      WebMock.disable_net_connect!(allow_localhost: true)
      @uv = UrlValidator.new(url: 'http://www.blahstackfood.com')
    end

    it 'retrieves a url' do
      stub_request(:head, 'http://www.blahstackfood.com').to_return(headers: { 'Content-Length' => 3 })
      success = uv.validate
      # [ uv.mime_type, uv.size, uv.url, uv.status_code, uv.redirected_to, uv.timed_out?, uv.redirected?, uv.correctly_formatted_url? ]
      expect(success).to eq(true)
      expect(uv.status_code).to eq(200)
    end

    it 'returns 481 (our own status) for text/html files and not success' do
      stub_request(:head, 'http://www.blahstackfood.com').to_return(
        headers: { 'Content-Length' => 3, 'content-type' => 'text/html; charset=us-ascii' }
      )
      resp = uv.validate
      # [ uv.mime_type, uv.size, uv.url, uv.status_code, uv.redirected_to, uv.timed_out?, uv.redirected?, uv.correctly_formatted_url? ]
      expect(resp).to eq(false)
      expect(uv.status_code).to eq(481)
    end

    it 'sets a 411 for a url with no content-length' do
      stub_request(:head, 'http://www.blahstackfood.com')
      success = uv.validate
      expect(success).to eq(false)
      expect(uv.status_code).to eq(411)
    end

    describe :mime_type_from do
      it 'extracts mime-types from content-type with charset' do
        content_type = 'text/plain; charset=us-ascii'
        headers = instance_double(HTTP::Message::Headers)
        allow(headers).to receive(:[]).with('Content-Type').and_return([content_type])
        response = instance_double(HTTP::Message)
        allow(response).to receive(:header).and_return(headers)
        expect(uv.send(:mime_type_from, response)).to eq('text/plain')
      end
    end

    describe :validate do

      attr_reader :client

      before(:each) do
        @client = instance_double(HTTPClient)
        allow(HTTPClient).to receive(:new).and_return(client)

        ssl_config = instance_double(HTTPClient::SSLConfig)
        allow(ssl_config).to receive(:verify_mode=)
        allow(client).to receive(:ssl_config).and_return(ssl_config)

        messages = %i[
          redirect_uri_callback=
          connect_timeout=
          send_timeout=
          receive_timeout=
          keep_alive_timeout=
        ].to_h { |k| [k, nil] }

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

      it 'retries with GET request in the event of a 500 or 503 from Google Drive' do
        [500, 503].each do |http_status_code|
          headers = instance_double(HTTP::Message::Headers)
          allow(headers).to receive(:[]).and_return([])
          head_response = instance_double(HTTP::Message)
          allow(head_response).to receive(:header).and_return(headers)
          allow(head_response).to receive(:status_code).and_return(http_status_code)

          prev_headers = instance_double(HTTP::Message::Headers)
          redirect_url = 'https://docs.googleusercontent.com/123'
          allow(prev_headers).to receive(:[]).with('Location').and_return([redirect_url])

          previous = instance_double(HTTP::Message)
          allow(previous).to receive(:header).and_return(prev_headers)
          allow(head_response).to receive(:previous).and_return(previous)

          expect(client).to receive(:head).and_return(head_response)

          expected_mime_type = 'application/octet-stream'
          expected_size = 12_345
          expected_filename = 'foo.bar'
          stub_request(:get, redirect_url).to_return(
            status: 200,
            headers: {
              'Content-Disposition' => "attachment; filename=\"#{expected_filename}\"",
              'Content-Type' => expected_mime_type,
              'Content-Length' => expected_size
            }
          )

          expect(uv.validate).to eq(true) # just to be sure
          expect(uv.redirected?).to eq(true)
          expect(uv.redirected_to).to eq(redirect_url)
          expect(uv.status_code).to eq(200)
          expect(uv.size).to eq(expected_size)
          expect(uv.mime_type).to eq(expected_mime_type)
          expect(uv.filename).to eq(expected_filename)
        end
      end

      it 'records redirects' do
        headers = instance_double(HTTP::Message::Headers)
        allow(headers).to receive(:[]) { |arg| { 'Content-Length' => 3 }[arg] }

        response = instance_double(HTTP::Message)
        allow(response).to receive(:header).and_return(headers)
        allow(response).to receive(:status_code).and_return(200)

        prev_headers = instance_double(HTTP::Message::Headers)
        redirect_url = 'http://example.org/foo.bar'
        allow(prev_headers).to receive(:[]).with('Location').and_return([redirect_url])

        previous = instance_double(HTTP::Message)
        allow(previous).to receive(:header).and_return(prev_headers)
        allow(response).to receive(:previous).and_return(previous)

        expect(client).to receive(:head).and_return(response)
        expect(uv.validate).to eq(true) # just to be sure
        expect(uv.redirected?).to eq(true)
        expect(uv.redirected_to).to eq(redirect_url)
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

    describe :upload_attributes_from do
      before(:each) do
        stub_request(:head, 'http://ftp.datadryad.org/InCuration/test-sfisher/My%20cAT%20hAS%20FlEaS.jpg')
          .to_return(status: 200, body: 'abc', headers: { 'Content-Length' => 3 })
      end

      it 'decodes and also makes prettier filenames with urlencoding' do
        url_validator = UrlValidator.new(url: 'http://ftp.datadryad.org/InCuration/test-sfisher/My%20cAT%20hAS%20FlEaS.jpg')
        resource = create(:resource)
        translator = Stash::UrlTranslator.new('http://ftp.datadryad.org/InCuration/test-sfisher/My%20cAT%20hAS%20FlEaS.jpg')
        result = url_validator.upload_attributes_from(translator: translator, resource: resource, association: 'data_files')

        expect(result[:upload_file_name]).to eq('My_cAT_hAS_FlEaS.jpg')
        expect(result[:original_filename]).to eq('My cAT hAS FlEaS.jpg')
      end
    end
  end
end

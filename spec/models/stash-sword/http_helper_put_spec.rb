require 'webmock/rspec'

module Stash
  module Sword
    describe HTTPHelper do

      # ------------------------------------------------------------
      # Fixture

      attr_writer :user_agent

      def user_agent
        @user_agent ||= 'elvis'
      end

      attr_writer :helper

      def helper
        @helper ||= HTTPHelper.new(user_agent: user_agent)
      end

      # ------------------------------------------------------------
      # Tests

      describe '#put' do
        it 'puts to the specified URI' do
          uri = URI('http://example.org/')
          stub_request(:put, uri)
          helper.put(uri: uri, payload: 'the payload')
          expect(a_request(:put, uri)).to have_been_made
        end

        it 'sends the payload' do
          uri = URI('http://example.org/')
          stub_request(:put, uri)

          payload = 'the payload'
          helper.put(uri: uri, payload: payload)

          expect(a_request(:put, uri).with do |req|
            expect(req.body).to eq(payload)
          end).to have_been_made
        end

        it 'sets the User-Agent header' do
          uri = URI('http://example.org/')
          stub_request(:put, uri)

          helper.put(uri: uri, payload: 'the payload')

          expect(a_request(:put, uri).with do |req|
            expect(req.headers).to include_header('User-Agent', user_agent)
          end).to have_been_made
        end

        it 'sets Basic-Auth headers' do
          username = 'elvis'
          password = 'presley'
          helper   = HTTPHelper.new(user_agent: user_agent, username: username, password: password)

          uri = URI('http://example.org/')
          stub_request(:put, uri.to_s).with(basic_auth: [username, password])

          helper.put(uri: uri, payload: 'the payload')
          expect(a_request(:put, uri.to_s)).to have_been_made
        end

        it 'sets other specified headers' do
          uri = URI('http://example.org/')
          stub_request(:put, uri)

          headers = {
            'Packaging' => 'http://purl.org/net/sword/package/SimpleZip',
            'Content-Type' => 'application/zip'
          }
          helper.put(uri: uri, payload: 'the payload', headers: headers)

          expect(a_request(:put, uri).with do |req|
            headers.each do |k, v|
              expect(req.headers).to include_header(k, v)
            end
          end).to have_been_made
        end

        it 'uses SSL for https requests' do
          uri           = URI('https://example.org/')
          uri_with_port = uri.to_s.sub('org/', 'org:443/')
          stub_request(:put, uri_with_port)
          helper.put(uri: uri, payload: 'the payload')
          expect(a_request(:put, uri_with_port)).to have_been_made
        end

        describe 'continuation' do
          it 'sends Expect: 100-continue'
          it 'sends the request body on a 100 Continue'
          it 'continues on a timeout in lieu of a 100 Continue'
          it 'redirects to put to a 302 Found'
          it 'respects the redirect limit'
          it 'fails on a 417 Expectation Failed'
        end
        describe 'responses' do
          it 'accepts a 200 OK'
          it 'accepts a 204 No Content'
          it 'accepts a 201 Created'
          it 'redirects to get a 303 See Other'
          it 'respects the redirect limit'
          it 'fails on a 4xx'
          it 'fails on a 5xx'
        end
      end

      describe '#put_file' do
        it 'puts to the specified URI'
        it 'sends the payload'
        it 'sets the User-Agent header'
        it 'sets Basic-Auth headers'
        it 'sets other specified headers'
        it 'uses SSL for https requests'

        describe 'continuation' do
          it 'sends Expect: 100-continue'
          it 'sends the request body on a 100 Continue'
          it 'continues on a timeout in lieu of a 100 Continue'
          it 'redirects to put to a 302 Found'
          it 'respects the redirect limit'
          it 'fails on a 417 Expectation Failed'
        end
        describe 'responses' do
          it 'accepts a 200 OK'
          it 'accepts a 204 No Content'
          it 'accepts a 201 Created'
          it 'redirects to get a 303 See Other'
          it 'respects the redirect limit'
          it 'fails on a 4xx'
          it 'fails on a 5xx'
        end
      end

    end
  end
end

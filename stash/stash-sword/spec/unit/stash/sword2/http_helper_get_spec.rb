require 'spec_helper'

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

      describe '#get' do

        # ------------------------------
        # Fixture

        before(:each) do
          @http = instance_double(Net::HTTP)
          allow(Net::HTTP).to receive(:new).and_return(@http)
          allow(@http).to receive(:start).and_yield(@http)
          @success = Net::HTTPOK.allocate
          @body = 'I am the body of the response'
          allow(@success).to receive(:body).and_return(@body)
        end

        # ------------------------------
        # Tests

        it 'gets the specified URI' do
          uri = URI('http://example.org/')
          expect(@http).to receive(:request).with(request.with_method('GET').with_uri(uri)).and_yield(@success)
          helper.get(uri: uri)
        end

        it 'gets a response' do
          expect(@http).to receive(:request).and_yield(@success)
          expect(helper.get(uri: URI('http://example.org/'))).to be(@body)
        end

        it 'sets the User-Agent header' do
          agent = 'Not Elvis'
          helper = HTTPHelper.new(user_agent: agent)
          expect(@http).to receive(:request).with(request.with_method('GET').with_headers('User-Agent' => agent)).and_yield(@success)
          helper.get(uri: URI('http://example.org/'))
        end

        it 'sets Basic-Auth headers' do
          uri = URI('http://example.org/')
          expect(@http).to receive(:request).with(request.with_method('GET').with_uri(uri).with_auth('elvis', 'presley')).and_yield(@success)
          helper = HTTPHelper.new(user_agent: user_agent, username: 'elvis', password: 'presley')
          helper.get(uri: uri)
        end

        it 'uses SSL for https requests' do
          uri = URI('https://example.org/')
          expect(Net::HTTP).to receive(:start).with(uri.hostname, uri.port, use_ssl: true).and_call_original
          expect(@http).to receive(:request).and_yield(@success)
          helper.get(uri: uri)
        end

        it 're-requests on receiving a 1xx' do
          uri = URI('http://example.org/')
          @info = Net::HTTPContinue.allocate

          expected = [@info, @success]
          expect(@http).to(
            receive(:request).twice.with(
              request.with_method('GET').with_uri(uri).with_headers('User-Agent' => user_agent)
            )
          ) do |&block|
            block.call(expected.shift)
          end

          expect(helper.get(uri: uri)).to be(@body)
        end

        it 'redirects on receiving a 3xx' do
          uri = URI('http://example.org/')
          uri2 = URI('http://example.org/new')
          @redirect = Net::HTTPMovedPermanently.allocate
          allow(@redirect).to receive(:[]).with('location').and_return(uri2.to_s)
          expect(@http).to receive(:request).with(
            request.with_method('GET').with_uri(uri).with_headers('User-Agent' => user_agent)
          ).and_yield(@redirect)
          expect(@http).to receive(:request).with(
            request.with_method('GET').with_uri(uri2).with_headers('User-Agent' => user_agent)
          ).and_yield(@success)
          expect(helper.get(uri: uri)).to be(@body)
        end

        it 'only redirects a limited number of times' do
          uri = URI('http://example.org/')
          @redirect = Net::HTTPMovedPermanently.allocate
          allow(@redirect).to receive(:[]).with('location').and_return(uri.to_s)
          expect(@http).to receive(:request).with(
            request.with_method('GET').with_uri(uri).with_headers('User-Agent' => user_agent)
          ).exactly(HTTPHelper::DEFAULT_MAX_REDIRECTS).times.and_yield(@redirect)
          expect { helper.get(uri: uri) }.to raise_error do |e|
            expect(e.message).to match(/Redirect limit.*exceeded.*#{uri.to_s}/)
          end
        end

        it 'fails on a 4xx' do
          @error = Net::HTTPForbidden
          allow(@error).to receive(:code).and_return(403)
          allow(@error).to receive(:message).and_return('Forbidden')
          expect(@http).to receive(:request).and_yield(@error)
          uri = URI('http://example.org/')
          expect { helper.get(uri: uri) }.to raise_error do |e|
            expect(e.message).to match(/403.*Forbidden.*#{uri.to_s}/)
          end
        end

        it 'fails on a 5xx' do
          @error = Net::HTTPServerError
          allow(@error).to receive(:code).and_return(500)
          allow(@error).to receive(:message).and_return('Internal Server Error')
          expect(@http).to receive(:request).and_yield(@error)
          uri = URI('http://example.org/')
          expect { helper.get(uri: uri) }.to raise_error do |e|
            expect(e.message).to match(/500.*Internal Server Error.*#{uri.to_s}/)
          end
        end
      end

    end
  end
end

require 'webmock/rspec'

module Stash
  module Sword
    describe Client do
      attr_reader :username, :client, :password, :on_behalf_of, :zipfile, :doi, :collection_uri

      before(:each) do
        @username       = 'ucb_dash_submitter'
        @password       = 'ucb_dash_password'
        @collection_uri = 'http://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/dash_ucb'
        @on_behalf_of   = 'ucb_dash_author'
        @client         = Client.new(collection_uri: @collection_uri, username: @username, password: @password, on_behalf_of: @on_behalf_of)
        @zipfile        = 'stash/stash-sword/examples/uploads/example.zip'
        @doi            = "doi:10.5072/FK#{Time.now.getutc.xmlschema.gsub(/[^0-9a-z]/i, '')}"
      end

      describe '#create' do

        attr_reader :body_xml

        before(:each) do
          @body_xml = <<-XML
            <entry xmlns="http://www.w3.org/2005/Atom">
              <id>http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4t157x4p</id>
              <author>
                <name>ucb_dash_submitter</name>
              </author>
              <generator uri="http://www.swordapp.org/" version="2.0" />
              <link href="http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4t157x4p" rel="edit" />
              <link href="http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4t157x4p" rel="http://purl.org/net/sword/terms/add" />
              <link href="http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4t157x4p" rel="edit-media" />
              <treatment xmlns="http://purl.org/net/sword/terms/">no treatment information available</treatment>
            </entry>
          XML
        end

        it 'POSTs with the correct headers' do
          stub_request(:post, collection_uri).with(basic_auth: [username, password]).to_return(
            body: body_xml
          )

          client.create(payload: zipfile, doi: doi)

          md5 = Digest::MD5.file(zipfile).to_s

          actual_headers = nil
          expect(a_request(:post, collection_uri).with do |req|
            actual_headers = req.headers
          end).to have_been_made

          expected_disposition = 'attachment'

          aggregate_failures('request headers') do
            {
              'On-Behalf-Of' => on_behalf_of,
              'Packaging' => 'http://purl.org/net/sword/package/SimpleZip',
              'Slug' => doi,
              'Content-Disposition' => "#{expected_disposition}; filename=example.zip",
              'Content-MD5' => md5,
              'Content-Length' => /[0-9]+/,
              'Content-Type' => 'application/zip'
            }.each do |k, v|
              expect(actual_headers).to include_header(k, v)
            end
          end
        end

        it 'allows Packaging to be overridden' do
          manifest = 'spec/data/manifest.checkm'
          stub_request(:post, collection_uri).with(basic_auth: [username, password]).to_return(
            body: body_xml
          )

          client.create(payload: manifest, doi: doi, packaging: Packaging::BINARY)

          md5 = Digest::MD5.file(manifest).to_s

          actual_headers = nil
          expect(a_request(:post, collection_uri).with do |req|
            actual_headers = req.headers
          end).to have_been_made

          expected_disposition = 'attachment'

          aggregate_failures('request headers') do
            {
              'On-Behalf-Of' => on_behalf_of,
              'Packaging' => 'http://purl.org/net/sword/package/Binary',
              'Slug' => doi,
              'Content-Disposition' => "#{expected_disposition}; filename=manifest.checkm",
              'Content-MD5' => md5,
              'Content-Length' => /[0-9]+/,
              'Content-Type' => 'application/octet-stream'
            }.each do |k, v|
              expect(actual_headers).to include_header(k, v)
            end
          end
        end

        it "gets the entry from the Edit-IRI in the Location: header if it isn't returned in the body" do
          redirect_url = 'http://www.example.org/'
          stub_request(:post, collection_uri).with(basic_auth: [username, password]).to_return(status: 201, headers: { 'Location' => redirect_url })
          stub_request(:get, redirect_url).with(basic_auth: [username, password]).to_return(
            body: body_xml
          )

          receipt = client.create(payload: zipfile, doi: doi)
          expect(receipt).to be_a(DepositReceipt)
        end

        it 'returns the entry'
        it 'forwards a success response'

        it 'forwards a 4xx error' do
          stub_request(:post, collection_uri).with(basic_auth: [username, password]).to_return(status: [403, 'Forbidden'])
          expect { client.create(payload: zipfile, doi: doi) }.to raise_error(RestClient::Forbidden)
        end

        it 'forwards a 5xx error' do
          stub_request(:post, collection_uri).with(basic_auth: [username, password]).to_return(status: [500, 'Internal Server Error'])
          expect { client.create(payload: zipfile, doi: doi) }.to raise_error(RestClient::InternalServerError)
        end

        it 'forwards an internal exception'
      end

      describe '#update' do
        it 'PUTs with the correct headers' do
          edit_iri = "http://merritt.cdlib.org/sword/v2/object/#{doi}"
          stub_request(:put, edit_iri).with(basic_auth: [username, password])

          code = client.update(edit_iri: edit_iri, payload: zipfile)
          expect(code).to eq(200)

          md5 = Digest::MD5.file(zipfile).to_s

          actual_body = nil
          actual_headers = nil
          expect(a_request(:put, edit_iri).with do |req|
            actual_body = req.body
            actual_headers = req.headers
          end).to have_been_made

          aggregate_failures('request headers') do
            {
              'Content-Length' => /[0-9]+/,
              'Content-Type' => %r{multipart/related; type="application/atom\+xml"; boundary=.*},
              'On-Behalf-Of' => on_behalf_of
            }.each do |k, v|
              expect(actual_headers).to include_header(k, v)
            end
          end

          expected_disposition = 'attachment'

          mime_headers = {
            'Packaging' => 'http://purl.org/net/sword/package/SimpleZip',
            'Content-Disposition' => "#{expected_disposition}; name=\"payload\"; filename=\"example.zip\"",
            'Content-Type' => 'application/zip',
            'Content-MD5' => md5
          }

          aggregate_failures('MIME headers') do
            mime_headers.each do |k, v|
              closest_match = actual_body[/#{k}[^\n]+/m].strip
              expect(actual_body).to include("#{k}: #{v}"), "expected '#{k}: #{v}'; closest match was '#{closest_match}'"
            end
          end
        end

        it 'allows Packaging to be overridden' do
          manifest = 'spec/data/manifest.checkm'

          edit_iri = "http://merritt.cdlib.org/sword/v2/object/#{doi}"
          stub_request(:put, edit_iri).with(basic_auth: [username, password])

          code = client.update(edit_iri: edit_iri, payload: manifest, packaging: Packaging::BINARY)
          expect(code).to eq(200)

          md5 = Digest::MD5.file(manifest).to_s

          actual_body = nil
          actual_headers = nil
          expect(a_request(:put, edit_iri).with do |req|
            actual_body = req.body
            actual_headers = req.headers
          end).to have_been_made

          aggregate_failures('request headers') do
            {
              'Content-Length' => /[0-9]+/,
              'Content-Type' => %r{multipart/related; type="application/atom\+xml"; boundary=.*},
              'On-Behalf-Of' => on_behalf_of
            }.each do |k, v|
              expect(actual_headers).to include_header(k, v)
            end
          end

          expected_disposition = 'attachment'

          mime_headers = {
            'Packaging' => 'http://purl.org/net/sword/package/Binary',
            'Content-Disposition' => "#{expected_disposition}; name=\"payload\"; filename=\"manifest.checkm\"",
            'Content-Type' => 'application/octet-stream',
            'Content-MD5' => md5
          }

          aggregate_failures('MIME headers') do
            mime_headers.each do |k, v|
              closest_match = actual_body[/#{k}[^\n]+/m].strip
              expect(actual_body).to include("#{k}: #{v}"), "expected '#{k}: #{v}'; closest match was '#{closest_match}'"
            end
          end
        end

        it 'follows redirects' do
          edit_iri = "http://merritt.cdlib.org/sword/v2/object/#{doi}"
          redirect_url = 'http://www.example.org/'
          stub_request(:put, edit_iri).with(basic_auth: [username, password]).to_return(status: 303, headers: { 'Location' => redirect_url })
          stub_request(:get, redirect_url).with(basic_auth: [username, password]).to_return(status: 200)
          code = client.update(edit_iri: edit_iri, payload: zipfile)
          expect(code).to eq(200)
        end

        it 'forwards a 4xx error' do
          edit_iri = "http://merritt.cdlib.org/sword/v2/object/#{doi}"
          stub_request(:put, edit_iri).with(basic_auth: [username, password]).to_return(status: [403, 'Forbidden'])
          expect { client.update(edit_iri: edit_iri, payload: zipfile) }.to raise_error(RestClient::Forbidden)
        end

        it 'forwards a 5xx error' do
          edit_iri = "http://merritt.cdlib.org/sword/v2/object/#{doi}"
          stub_request(:put, edit_iri).with(basic_auth: [username, password]).to_return(status: [500, 'Internal Server Error'])
          expect { client.update(edit_iri: edit_iri, payload: zipfile) }.to raise_error(RestClient::InternalServerError)
        end

        it 'forwards an internal exception'
      end

    end
  end
end

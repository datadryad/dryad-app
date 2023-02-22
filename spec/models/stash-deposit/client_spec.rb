require 'webmock/rspec'

module Stash
  module Deposit
    describe Client do

      before(:each) do
        @username       = 'ucb_dash_submitter'
        @password       = 'ucb_dash_password'
        @mrt_uri        = 'https://merritt-stage.cdlib.org/object/update'
        @collection_uri = 'http://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/dash_ucb'
        @on_behalf_of   = 'ucb_dash_author'
        @client         = Client.new(collection_uri: @collection_uri, username: @username, password: @password, on_behalf_of: @on_behalf_of)

        @manifest       = 'spec/data/manifest.checkm'
        @doi            = "doi:10.5072/FK#{Time.now.getutc.xmlschema.gsub(/[^0-9a-z]/i, '')}"

        @merritt_output = { 'bat:batchState' =>
                             { 'xmlns:bat' => 'http://uc3.cdlib.org/ontology/mrt/ingest/batch',
                               'bat:batchID' => 'bid-9dee0fbd-b674-44ce-abc0-937f5a0afed8',
                               'bat:jobStates' => '',
                               'bat:batchStatus' => 'QUEUED',
                               'bat:userAgent' => 'dash_demo_user/Dash Demo User',
                               'bat:submissionDate' => '2023-02-17T15:26:38-08:00' } }.to_json
      end

      describe '#create' do

        it 'successfully sends a request to Merritt' do
          stub_request(:post, @mrt_uri).with(basic_auth: [@username, @password])
            .to_return(status: 200, body: @merritt_output)
          resp = @client.create(payload: @manifest, doi: @doi)
          expect(resp.code).to eq(200)
        end

        it 'raises an error for a 4xx error' do
          stub_request(:post, @mrt_uri).with(basic_auth: [@username, @password]).to_return(status: [403, 'Forbidden'])
          expect { @client.create(payload: @manifest, doi: @doi) }.to raise_error(Stash::Deposit::ResponseError)
        end

        it 'forwards a 5xx error' do
          stub_request(:post, @mrt_uri).with(basic_auth: [@username, @password]).to_return(status: [500, 'Internal Server Error'])
          expect { @client.create(payload: @manifest, doi: @doi) }.to raise_error(Stash::Deposit::ResponseError)
        end

      end

      describe '#update' do
        before(:each) do
          @download_uri = 'https://merritt-stage.cdlib.org/d/ark%3A%2F99999%2Ffk4t73qx90'
        end

        it 'successfully sends a request to Merritt' do
          stub_request(:post, @mrt_uri).with(basic_auth: [@username, @password])
            .to_return(status: 200, body: @merritt_output)
          resp = @client.update(payload: @manifest, doi: @doi, download_uri: @download_uri)
          expect(resp.code).to eq(200)
        end

        it 'raises an error for a 4xx error' do
          stub_request(:post, @mrt_uri).with(basic_auth: [@username, @password]).to_return(status: [403, 'Forbidden'])
          expect { @client.update(payload: @manifest, doi: @doi, download_uri: @download_uri) }
            .to raise_error(Stash::Deposit::ResponseError)
        end
      end

    end
  end
end

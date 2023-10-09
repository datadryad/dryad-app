require 'securerandom'

module Stash
  module ZenodoSoftware
    module WebmocksHelper

      def stub_get_existing_ds(deposition_id:)
        simple = simple_body(deposition_id: deposition_id)
        stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}?access_token=ThisIsAFakeToken")
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200,
                     body: simple.merge(state: 'unsubmitted').to_json,
                     headers: { 'Content-Type' => 'application/json' })
        simple[:links][:bucket]
      end

      def stub_get_existing_closed_ds(deposition_id:)
        simple = simple_body(deposition_id: deposition_id)
        stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}?access_token=ThisIsAFakeToken")
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200,
                     body: simple.merge(state: 'done').to_json,
                     headers: { 'Content-Type' => 'application/json' })
        simple[:links][:bucket]
      end

      def stub_put_metadata(deposition_id:)
        stub_request(:put, "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}?access_token=ThisIsAFakeToken")
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200,
                     body: simple_body(deposition_id: deposition_id).merge(state: 'done').to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      # returns the deposition_id and bucket link
      def stub_new_dataset
        deposition_id = rand.to_s[2..8].to_i
        simple = simple_body(deposition_id: deposition_id)
        stub_request(:post, 'https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken')
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200,
                     body: simple.merge(state: 'unsubmitted').to_json,
                     headers: { 'Content-Type' => 'application/json' })
        [deposition_id, simple[:links][:bucket]]
      end

      def stub_new_version_process(deposition_id:)
        new_deposition_id = rand.to_s[2..8].to_i
        new_link = "https://sandbox.zenodo.org/api/deposit/depositions/#{new_deposition_id}?access_token=ThisIsAFakeToken"

        stub_request(:post, "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}/actions/newversion?access_token=ThisIsAFakeToken")
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200,
                     body: { links: { latest_draft: new_link } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_get_existing_ds(deposition_id: new_deposition_id)
        new_deposition_id
      end

      def stub_new_access_token
        stub_request(:post, "https://sandbox.zenodo.org/oauth/token").
          with(
            body: {"client_id"=> 'zenodo_client_id', "client_secret"=> 'zenodo_client_secret', "grant_type"=>"client_credentials", "scope"=>"user:email"},
            ).to_return(status: 200, body: {access_token: 'ThisIsAFakeToken', expires_in: 3600}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      def simple_body(deposition_id:)
        { id: deposition_id,
          conceptrecid: deposition_id - 1,
          links: links(deposition_id: deposition_id),
          metadata: metadata(deposition_id: deposition_id) }
      end

      def stub_existing_files(deposition_id:, filenames: [], filesizes: [])
        files = filenames.map.with_index do |fn, idx|
          { filename: fn, filesize: filesizes[idx] }
        end
        resp_data = { files: files }.with_indifferent_access
        stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}?access_token=ThisIsAFakeToken")
          .with(
            headers: {
              'Content-Type' => 'application/json'
            }
          ).to_return(status: 200, body: resp_data.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      def links(deposition_id:)
        # latest_draft should look something like this with a different deposition_id, though
        {
          latest_draft: "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id + 1}/actions/edit",
          edit: "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}/actions/edit",
          publish: "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}/actions/publish",
          bucket: "https://sandbox.zenodo.org/api/files/#{SecureRandom.uuid}"
        }
      end

      def metadata(deposition_id:)
        { prereserve_doi: { doi: "10.5072/zenodo.#{deposition_id}" } }
      end
    end
  end
end

module Stash
  module ZenodoSoftware
    module WebmocksHelper

      def stub_get_existing_ds(deposition_id:)
        stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}?access_token=ThisIsAFakeToken")
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200,
                     body: simple_body(deposition_id: deposition_id).to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_existing_closed_ds(deposition_id:)
        stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}?access_token=ThisIsAFakeToken")
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200,
                     body: simple_body(deposition_id: deposition_id).merge(state: 'done').to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      def simple_body(deposition_id:)
        { id: deposition_id,
          conceptrecid: deposition_id - 1,
          links: links(deposition_id: deposition_id),
          metadata: metadata(deposition_id: deposition_id) }
      end

      def links(deposition_id:)
        # latest_draft should look something like this with a different deposition_id, though
        {
          latest_draft: "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id + 1}/actions/edit",
          edit: "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}/actions/edit",
          publish: "https://sandbox.zenodo.org/api/deposit/depositions/#{deposition_id}/actions/publish"
        }
      end

      def metadata(deposition_id:)
        { prereserve_doi: { doi: "10.5072/zenodo.#{deposition_id}" } }
      end
    end
  end
end

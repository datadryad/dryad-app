require 'stash/zenodo_replicate/zenodo_connection'

module Stash
  module ZenodoReplicate
    class Deposit

      attr_reader :resource, :deposition_id, :links

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      def initialize(resource:)
        @resource = resource
      end

      # this creates a new deposit and returns the json response if successful
      # POST /api/deposit/depositions
      def new_deposition
        # mg = MetadataGenerator.new(resource: @resource)
        resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions", json: {})

        @deposition_id = resp[:id]
        @links = resp[:links]

        resp
      end

      # PUT /api/deposit/depositions/123
      # Need to have gotten or created the deposition for this to work
      # If passing in a DOI then the metadata generator doesn't use the one from the main dataset, but the one you say instead
      def update_metadata(doi: nil)
        mg = MetadataGenerator.new(resource: @resource, use_zenodo_doi: !doi.nil?)
        my_metadata = mg.metadata
        my_metadata[:doi] = doi unless doi.nil?
        ZC.standard_request(:put, "#{ZC.base_url}/api/deposit/depositions/#{@deposition_id}", json: { metadata: my_metadata })
      end

      # GET /api/deposit/depositions/123
      def get_by_deposition(deposition_id:)
        resp = ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}")

        @deposition_id = resp[:id]
        @links = resp[:links]

        resp
      end

      def new_version(deposition_id:)
        # a two-step process according to the notes -- newversion and then get the latest draft link out and get that item for editing
        resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}/actions/newversion")

        resp2 = ZC.standard_request(:get, resp[:links][:latest_draft])

        @deposition_id = resp2[:id]
        @links = resp2[:links]

        resp2
      end

      def reopen_for_editing
        ZC.standard_request(:post, @links[:edit])
      end

      # POST /api/deposit/depositions/456/actions/publish
      # Need to have gotten or created the deposition for this to work
      def publish
        ZC.standard_request(:post, @links[:publish])
      end
    end
  end
end

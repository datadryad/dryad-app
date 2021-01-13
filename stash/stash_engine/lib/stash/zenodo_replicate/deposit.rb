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
      def update_metadata(manual_metadata: nil)
        if manual_metadata.nil?
          mg = MetadataGenerator.new(resource: @resource)
          manual_metadata = mg.metadata
        end
        ZC.standard_request(:put, "#{ZC.base_url}/api/deposit/depositions/#{@deposition_id}", json: { metadata: manual_metadata })
      end

      # GET /api/deposit/depositions/123
      def get_by_deposition(deposition_id:)
        resp = ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}")

        @deposition_id = resp[:id]
        @links = resp[:links]

        resp
      end

      # POST /api/deposit/depositions/123/actions/edit
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

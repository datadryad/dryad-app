require 'stash/zenodo_replicate/zenodo_connection'

module Stash
  module ZenodoReplicate
    class Deposit

      attr_reader :resource, :deposition_id

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
        @files = resp[:files]

        resp
      end

      # deposition_id is an integer that zenodo gives us on deposit and this generates a new version with a new id
      # POST /api/deposit/depositions/123/actions/newversion
      def new_version_deposition(deposition_id:)
        # mg = MetadataGenerator.new(resource: @resource)
        resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions/#{deposit_id}/actions/newversion")

        raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp}" unless r.status.success?

        @deposition_id = resp[:id]
        @links = resp[:links]
        @files = resp[:files]

        resp
      end

      # PUT /api/deposit/depositions/123
      # Need to have gotten or created the deposition for this to work
      def update_metadata
        mg = MetadataGenerator.new(resource: @resource)

        ZC.standard_request(:put, @links[:latest_draft], json: { metadata: mg.metadata })
      end

      # GET /api/deposit/depositions/123
      def get_by_deposition(deposition_id:)
        resp = ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}")

        @deposition_id = resp[:id]
        @links = resp[:links]
        @files = resp[:files]

        resp
      end

      # POST /api/deposit/depositions/456/actions/publish
      # Need to have gotten or created the deposition for this to work
      def publish
        ZC.standard_request(:post, @links[:publish])
      end
    end
  end
end

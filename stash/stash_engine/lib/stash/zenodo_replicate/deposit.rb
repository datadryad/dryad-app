require 'stash/zenodo_replicate/zenodo_connection'

module Stash
  module ZenodoReplicate
    class Deposit

      attr_reader :resource, :file_collection, :deposit_id, :links, :files

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      def initialize(resource:, file_collection:)
        @resource = resource
        @file_collection = file_collection
      end

      # this creates a new deposit and adds metadata at the same time and returns the json response if successful, errors if already exists
      def new_deposition
        mg = MetadataGenerator.new(resource: @resource)
        resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions", json: { metadata: mg.metadata })

        @deposit_id = resp[:id]
        @links = resp[:links]

        # state is unsubmitted at this point
        resp
      end

      # deposition_id is an integer that zenodo gives us on deposit and this generates a new version with a new id, but
      # currently unused
      def new_version_deposition(deposit_id:)
        # POST /api/deposit/depositions/123/actions/newversion
        mg = MetadataGenerator.new(resource: @resource)
        resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions/#{deposit_id}/actions/newversion")

        raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp}" unless r.status.success?

        @deposit_id = resp[:id]
        @links = resp[:links]
        @files = resp[:files]

        resp
      end

      def put_metadata
        mg = MetadataGenerator.new(resource: @resource)

        resp = ZC.standard_request(:put, @links[:latest_draft], json: { metadata: mg.metadata })

        # {"status"=>400, "message"=>"Validation error.", "errors"=>[{"field"=>"metadata.doi", "message"=>"DOI already exists in Zenodo."}]}

        @deposit_id = resp[:id]
        @links = resp[:links]

        resp
      end

      def get_by_deposition(deposit_id:)
        resp = ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{deposit_id}")

        @deposit_id = resp[:id]
        @links = resp[:links]
        @files = resp[:files]

        resp
      end

      def publish
        ZC.standard_request(:post, links[:publish])
      end
    end
  end
end

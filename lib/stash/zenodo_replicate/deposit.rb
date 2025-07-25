require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_replicate/metadata_generator'

module Stash
  module ZenodoReplicate
    class Deposit

      attr_reader :resource, :deposition_id, :links, :zc

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      def initialize(resource:, zc_id:)
        @resource = resource
        @zc_id = zc_id
        @zc = StashEngine::ZenodoCopy.where(id: @zc_id).first
      end

      # this creates a new deposit and returns the json response if successful
      # POST /api/deposit/depositions
      def new_deposition(pre_reserve_doi: false)
        # mg = MetadataGenerator.new(resource: @resource)
        json = (pre_reserve_doi ? { metadata: { prereserve_doi: true } } : {})
        resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions", json: json,
                                                                                    zc_id: @zc_id)

        @deposition_id = resp[:id]
        @links = resp[:links]

        resp
      end

      # PUT /api/deposit/depositions/123
      # Need to have gotten or created the deposition for this to work
      # If passing in a DOI then the metadata generator doesn't use the one from the main dataset, but the one you say instead
      def update_metadata(dataset_type: :data, doi: nil, manual_metadata: nil)
        if manual_metadata.nil?
          mg = Stash::ZenodoReplicate::MetadataGenerator.new(resource: @resource, dataset_type: dataset_type)
          manual_metadata = mg.metadata
        end
        manual_metadata[:doi] = doi unless doi.nil?
        ZC.standard_request(:put, "#{ZC.base_url}/api/deposit/depositions/#{@deposition_id}",
                            json: { metadata: manual_metadata }, zc_id: @zc_id)
      end

      def self.get_by_deposition(deposition_id:, zc_id:)
        ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}", zc_id: zc_id)
      end

      # GET /api/deposit/depositions/123
      def get_by_deposition(deposition_id:)
        resp = Deposit.get_by_deposition(deposition_id: deposition_id, zc_id: @zc_id)

        @deposition_id = resp[:id]
        @links = resp[:links]

        resp
      end

      def new_version(deposition_id:)
        # a two-step process according to the notes -- newversion and then get the latest draft link out and get that item for editing
        resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}/actions/newversion",
                                   zc_id: @zc_id)

        resp2 = ZC.standard_request(:get, resp[:links][:latest_draft], zc_id: @zc_id)

        @deposition_id = resp2[:id]
        @links = resp2[:links]

        resp2
      end

      # POST /api/deposit/depositions/123/actions/edit
      def reopen_for_editing
        ZC.standard_request(:post, @links[:edit], zc_id: @zc_id)
      end

      # POST /api/deposit/depositions/456/actions/publish
      # Need to have gotten or created the deposition for this to work
      def publish
        1.upto(3) do |_count|
          r2 = dataset_info
          if r2[:submitted] == true
            ZC.log_to_database(item: 'The dataset is confirmed submitted in Zenodo.', zen_copy: @zc)
            return r2
          end

          begin
            ZC.standard_request(:post, @links[:publish], zc_id: @zc_id)
          rescue Stash::ZenodoReplicate::ZenodoError => e
            ZC.log_to_database(item: "ZenodoError on publication: #{e}", zen_copy: @zc)
          end
          sleep(5)
        end
        r2 = dataset_info
        return r2 if r2[:submitted] == true

        raise Stash::ZenodoReplicate::ZenodoError, "identifier_id #{@zc.identifier_id}: Publication failed after " \
                                                   'three attempts. Are Zenodo systems up and stable?'
      end

      def delete
        ZC.standard_request(:delete, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}", zc_id: @zc_id)
      end

      def dataset_info
        ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}", zc_id: @zc_id)
      end

    end
  end
end

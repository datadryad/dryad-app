require 'byebug'
require 'stash/zenodo_replicate/metadata_generator'
require 'stash/zenodo_replicate/deposit'

module Tasks
  module Zenodo
    class Metadata

      def initialize(zenodo_copy:)
        @zc = zenodo_copy
        @resource = StashEngine::Resource.where(id: @zc.resource_id).first
      end

      def dataset_type
        return :data if @zc.copy_type == 'data'

        return :supp if @zc.copy_type&.start_with?('supp')

        :software
      end

      # this may be a different doi than the main one for software/supplemental (zenodo generated one we save)
      def smart_doi
        return nil if @zc.software_doi.blank?

        @zc.software_doi
      end

      def update_metadata
        return if @zc.deposition_id.blank? || @zc.state != 'finished' || @resource.nil? # it isn't update-able

        deposit = Stash::ZenodoReplicate::Deposit.new(resource: @resource)
        resp = deposit.get_by_deposition(deposition_id: @zc.deposition_id)

        if resp[:state] == 'done'
          deposit.reopen_for_editing
          deposit.update_metadata(dataset_type: dataset_type, doi: smart_doi)
          deposit.publish
        else
          deposit.update_metadata(dataset_type: dataset_type, doi: smart_doi)
        end
      end
    end
  end
end

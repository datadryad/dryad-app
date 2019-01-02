# instantiate IdGen with make_class and
# call mint_id and update_metadata for it to choose and mint the right types of ids based on tenant config
# require 'stash/doi/datacite_gen'
# require 'stash/doi/ezid_gen'

module Stash
  module Doi
    class IdGen
      attr_reader :resource

      # this is to take the place of the normal initialize to create a class of the correct type
      def self.make_instance(resource:)
        id_svc = resource.tenant.identifier_service
        if id_svc.provider == 'ezid'
          EzidGen.new(resource: resource)
        elsif id_svc.provider == 'datacite'
          DataciteGen.new(resource: resource)
        end
      end

      def initialize(resource:)
        @resource = resource
      end

      # subclasses should implement mint_id and update_metadata(dc4_xml:, landing_page_url:) methods
      private

      def tenant
        resource.tenant
      end

      def id_params
        @id_params ||= tenant.identifier_service
      end

      def owner
        id_params.owner
      end

      def password
        id_params.password
      end

      def account
        id_params.account
      end

    end
  end
end

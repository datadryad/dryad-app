require 'stash_ezid/client'

module Stash
  module Merritt
    class EzidHelper
      attr_reader :resource

      def initialize(resource:)
        @resource = resource
      end

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
        ezid_client.mint_id
      end

      def update_metadata(dc4_xml:, landing_page_url:)
        identifier_str = resource.identifier_str
        ezid_client.update_metadata(identifier_str, dc4_xml, landing_page_url)
      end

      private

      def tenant
        resource.tenant
      end

      def ezid_client
        @ezid_client ||= begin
          id_params = tenant.identifier_service
          StashEzid::Client.new(
            shoulder: id_params.shoulder,
            account: id_params.account,
            password: id_params.password,
            owner: id_params.owner,
            id_scheme: id_params.scheme
          )
        end
      end
    end
  end
end

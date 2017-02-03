require 'stash_ezid/client'

module Stash
  module Merritt
    class EzidHelper
      attr_reader :resource

      def initialize(resource:)
        @resource = resource
      end

      # @return [String] the identifier (DOI, ARK, or URN)
      def ensure_identifier
        identifier_str = resource.identifier_str
        return identifier_str if identifier_str

        new_identifier_str = ezid_client.mint_id
        resource.ensure_identifier(new_identifier_str)
        new_identifier_str
      end

      def update_metadata(dc3_xml:, landing_page_url:)
        identifier_str = resource.identifier_str
        ezid_client.update_metadata(identifier_str, dc3_xml, landing_page_url)
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

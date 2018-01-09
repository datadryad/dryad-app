require 'ezid/client'

module Stash
  module Merritt
    class EzidHelper
      attr_reader :resource

      def initialize(resource:)
        @resource = resource
      end

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
        ezid_response = ezid_client.mint_identifier(shoulder, status: 'reserved', profile: 'datacite')
        ezid_response.id
      end

      def update_metadata(dc4_xml:, landing_page_url:)
        params = { status: 'public', datacite: dc4_xml }
        params[:owner] = owner unless owner.blank?
        params[:target] = landing_page_url if landing_page_url
        ezid_client.modify_identifier(resource.identifier_str, params)
      end

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

      def shoulder
        id_params.shoulder
      end

      def ezid_client
        @ezid_client ||= ::Ezid::Client.new(host: StashEngine.app.ezid.host, port: StashEngine.app.ezid.port,
                                            user: account, password: password)
      end

    end
  end
end

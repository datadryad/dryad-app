require 'ezid/client'
# require_relative 'id_gen'

module Stash
  module Merritt
    class EzidGen < IdGen

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

      def shoulder
        id_params.shoulder
      end

      def ezid_client
        @ezid_client ||= ::Ezid::Client.new(host: ezid_host, port: ezid_port,
                                            user: account, password: password)
      end

      def ezid_host
        StashEngine.app.ezid.host
      end

      def ezid_port
        StashEngine.app.ezid.port
      end

    end
  end
end

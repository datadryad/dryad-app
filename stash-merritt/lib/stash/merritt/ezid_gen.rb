require 'ezid/client'
# require_relative 'id_gen'

module Stash
  module Merritt
    class EzidGen < IdGen

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
        if id_exists?
          ezid_client.create_identifier(doi, status: 'reserved', profile: 'datacite')
        else
          ezid_response = ezid_client.mint_identifier(shoulder, status: 'reserved', profile: 'datacite')
          ezid_response.id
        end
      end

      def id_exists?
        my_id = @resource.identifier
        return false if my_id.nil? || my_id.identifier.blank?
        begin
          ezid_client.get_identifier_metadata(my_id.to_s)
        rescue Ezid::IdentifierNotFoundError => ex
          return false
        end
        return true
      end

      # reserve DOI in string format like "doi:xx.xxx/yyyyy" and return ID string after reserving it.
      def reserve_id(doi:)
        if id_exists?
          return @resource.identifier.to_s
        else
          ezid_client.create_identifier(doi, status: 'reserved', profile: 'datacite')
          return doi
        end
      end

      def update_metadata(dc4_xml:, landing_page_url:)
        params = {status: 'public', datacite: dc4_xml}
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

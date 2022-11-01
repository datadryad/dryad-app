require 'ezid/client'

module Stash
  module Doi
    class EzidError < IdGenError; end

    class EzidGen < IdGen

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
        if id_exists?
          ezid_client.create_identifier(doi, status: 'reserved', profile: 'datacite')
        else
          ezid_response = ezid_client.mint_identifier(shoulder, status: 'reserved', profile: 'datacite')
          ezid_response.id
        end
      rescue Ezid::Error => e
        err = EzidError.new("Ezid failed to mint an id (#{e.message})")
        err.set_backtrace(e.backtrace) if e.backtrace.present?
        raise err
      end

      def id_exists?
        my_id = @resource.identifier
        return false if my_id.nil? || my_id.identifier.blank?

        begin
          ezid_client.get_identifier_metadata(my_id.to_s)
        rescue Ezid::IdentifierNotFoundError
          return false
        end
        true
      end

      # reserve DOI in string format like "doi:xx.xxx/yyyyy" and return ID string after reserving it.
      def reserve_id(doi:)
        if id_exists?
          @resource.identifier.to_s
        else
          ezid_client.create_identifier(doi, status: 'reserved', profile: 'datacite')
          doi
        end
      rescue Ezid::Error => e
        err = EzidError.new("Ezid failed to reserver an id for resource #{resource&.identifier_str}" \
                            " (#{e.message}) with doi: #{doi}")
        err.set_backtrace(e.backtrace) if e.backtrace.present?
        raise err
      end

      def update_metadata(dc4_xml:, landing_page_url:)
        params = { status: 'public', datacite: dc4_xml }
        params[:owner] = owner unless owner.blank?
        params[:target] = landing_page_url if landing_page_url
        ezid_client.modify_identifier(resource.identifier_str, params)
      rescue Ezid::Error => e
        err = EzidError.new("Ezid failed to update metadata for resource #{resource&.identifier_str} (#{e.message}) with params: #{params.inspect}")
        err.set_backtrace(e.backtrace) if e.backtrace.present?
        raise err
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
        APP_CONFIG.ezid.host
      end

      def ezid_port
        APP_CONFIG.ezid.port
      end

    end
  end
end

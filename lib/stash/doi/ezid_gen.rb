require 'ezid/client'

module Stash
  module Doi
    class EzidError < IdGenError; end

    class EzidGen < IdGen

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

      def update_metadata(dc4_xml:, landing_page_url:)
        params = { status: 'public', datacite: dc4_xml }
        params[:owner] = owner unless owner.blank?
        params[:target] = landing_page_url if landing_page_url
        ezid_client.modify_identifier(resource.identifier_str, **params)
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

require 'stash/sword'
require 'rest-client' # so we have access to its exception classes

module Stash
  module Merritt
    class SwordHelper

      class GoneAsynchronous < StandardError; end

      attr_reader :logger, :package

      def initialize(package:, logger: nil)
        @logger = logger
        @package = package
      end

      def submit!
        if (update_uri = resource.update_uri)
          do_update(update_uri)
        else
          do_create
        end
      rescue RestClient::Exceptions::ReadTimeout, RestClient::InternalServerError, RestClient::ServiceUnavailable
        raise GoneAsynchronous
      ensure
        resource.version_zipfile = File.basename(package.payload)
        resource.save!
      end

      private

      def resource
        package.resource
      end

      def tenant
        resource.tenant
      end

      def identifier_str
        resource.identifier_str
      end

      def sword_client
        @sword_client ||= Stash::Sword::Client.new(logger: logger, **tenant.sword_params)
      end

      def do_create
        receipt = sword_client.create(doi: identifier_str, payload: package.payload, packaging: package.packaging)
        resource.download_uri = receipt.em_iri
        resource.update_uri = receipt.edit_iri
      end

      def do_update(update_uri)
        sword_client.update(edit_iri: update_uri, payload: package.payload, packaging: package.packaging)
      end

    end
  end
end

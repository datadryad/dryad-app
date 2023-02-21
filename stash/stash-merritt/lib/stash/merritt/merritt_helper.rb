require 'stash/deposit'

module Stash
  module Merritt
    class MerrittHelper

      attr_reader :logger, :package

      def initialize(package:, logger: nil)
        @logger = logger
        @package = package
      end

      def submit!
        if resource.update_uri
          do_update
        else
          do_create
        end

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

      def merritt_client
        @merritt_client ||= Stash::Deposit::Client.new(logger: logger, **tenant.sword_params)
      end

      def do_create
        merritt_client.create(doi: identifier_str, payload: package.payload)
        # resource.download_uri = receipt.em_iri
        # resource.update_uri = receipt.edit_iri
      end

      def do_update
        merritt_client.update(doi: identifier_str, payload: package.payload, download_uri: resource.download_uri)
      end

    end
  end
end

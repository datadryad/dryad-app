# require_relative 'id_gen'
require 'cirneco'

module Stash
  module Merritt
    class DataciteError < StandardError; end

    class DataciteGen < IdGen

      include Cirneco::Api

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
        datacenter = Cirneco::DataCenter.new(prefix: prefix, username: account, password: password)
        base_id = datacenter.encode_doi(prefix)
        "doi:#{base_id}"
      end

      def update_metadata(dc4_xml:, landing_page_url:)
        # the doi apparently is known from the DC xml document
        response = post_metadata(dc4_xml, username: account, password: password, sandbox: sandbox)
        validate_response(response: response, operation: 'update metadata')

        response = put_doi(bare_identifier, username: account, password: password, sandbox: sandbox, url: landing_page_url)
        validate_response(response: response, operation: 'update target')
      end

      private

      # strip off the icky doi: at the first
      def bare_identifier
        resource.identifier_str.gsub(/^doi\:/, '')
      end

      def prefix
        id_params.prefix
      end

      def sandbox
        id_params.sandbox
      end

      def validate_response(response:, operation:)
        raise DataciteError, "DataCite failed to #{operation} for resource #{resource.id}" unless response.status == 201
      end

    end
  end
end

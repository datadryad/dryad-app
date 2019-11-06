require 'cirneco'
require 'ostruct'

module Stash
  module Doi
    class DataciteError < IdGenError; end

    class DataciteGen < IdGen

      include Cirneco::Api

      def ping(identifier)
        get_doi(identifier, username: account, password: password, sandbox: sandbox)
      end

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
        # datacenter = Cirneco::DataCenter.new(prefix: prefix, username: account, password: password)
        base_id = "#{prefix}/dryad.#{StashEngine::NoidState.mint}"
        "doi:#{base_id}"
      end

      # reserve DOI in string format like "doi:xx.xxx/yyyyy" and return ID string after reserving it.
      # I don't believe DataCite does the reserving thing like EZID.  This goes nowhere and does nothing and just
      # to keep the interface consistent between DataCite and EZID.
      def reserve_id(doi:)
        doi
      end

      def update_metadata(dc4_xml:, landing_page_url:)
        # the doi apparently is known from the DC xml document
        response = post_metadata(dc4_xml, username: account, password: password, sandbox: sandbox)
        validate_response(response: response, operation: 'update metadata')

        response = put_doi(bare_identifier, username: account, password: password, sandbox: sandbox, url: landing_page_url)
        validate_response(response: response, operation: 'update target')
      rescue Faraday::ConnectionFailed, Faraday::ResourceNotFound, Faraday::TimeoutError, Faraday::ClientError => e
        err = DataciteError.new("Datacite failed to update metadata for resource #{resource&.identifier_str}" \
                                " (#{e.message}) with params: #{dc4_xml.inspect}")
        err.set_backtrace(e.backtrace) if e.backtrace.present?
        raise err
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
        raise DataciteError, "DataCite failed to #{operation} for resource #{@resource&.id} -- #{response.inspect}" unless response.status == 201
      end

    end
  end
end

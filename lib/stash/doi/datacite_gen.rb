require 'ostruct'
require_relative '../download'

module Stash
  module Doi
    class DataciteError < IdGenError; end

    class DataciteGen < IdGen

      def ping(identifier)
        get_doi(identifier, username: account, password: password, sandbox: sandbox)
      end

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
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
        # add breakpoint here to get a peek at the XML being sent to DataCite
        # the doi apparently is known from the DC xml document
        response = post_metadata(dc4_xml, username: account, password: password, sandbox: sandbox)
        validate_response(response: response, operation: 'update metadata')

        response = put_doi(bare_identifier, username: account, password: password, sandbox: sandbox, url: landing_page_url)
        validate_response(response: response, operation: 'update target')
      rescue HTTP::Error => e
        err = DataciteError.new("Datacite failed to update metadata for resource #{resource&.identifier_str} " \
                                "(#{e.message}) with params: #{dc4_xml.inspect}")
        err.set_backtrace(e.backtrace) if e.backtrace.present?
        raise err
      end

      private

      # strip off the icky doi: at the first
      def bare_identifier
        resource.identifier_str.gsub(/^doi:/, '')
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

      def post_metadata(data, options = {})
        unless options[:username].present? && options[:password].present?
          return OpenStruct.new(body: { 'errors' => [{ 'title' => 'Username or password missing' }] })
        end

        mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'
        url = "#{mds_url}/metadata"

        http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
          .timeout(connect: 30, read: 60).timeout(60).follow(max_hops: 10)
          .basic_auth(user: options[:username], pass: options[:password])

        headers = { content_type: 'application/xml;charset=UTF-8' }
        http.post(url, headers: headers, body: data)
      end

      # replacement for Cirneco which isn't working with Ruby 2.6.6 (because of Maremma?)
      def put_doi(doi, options = {})
        unless options[:username].present? && options[:password].present?
          return OpenStruct.new(body: { 'errors' => [{ 'title' => 'Username or password missing' }] })
        end

        payload = "doi=#{doi}\nurl=#{options[:url]}"
        mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'
        url = "#{mds_url}/doi/#{doi}"

        http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
          .timeout(connect: 30, read: 60).timeout(60).follow(max_hops: 10)
          .basic_auth(user: options[:username], pass: options[:password])

        headers = { content_type: 'application/xml;charset=UTF-8' }
        http.put(url, headers: headers, body: payload)
      end

      def get_doi(doi, options = {})
        unless options[:username].present? && options[:password].present?
          return OpenStruct.new(body: { 'errors' => [{ 'title' => 'Username or password missing' }] })
        end

        mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'
        url = "#{mds_url}/doi/#{doi}"

        http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
          .timeout(connect: 30, read: 60).timeout(60).follow(max_hops: 10)
          .basic_auth(user: options[:username], pass: options[:password])

        http.get(url)
      end

    end
  end
end

require 'ostruct'
require_relative '../download'

module Stash
  module Doi
    class DataciteGenError < StandardError; end
    class DataciteError < DataciteGenError; end

    class DataciteGen
      attr_reader :resource

      def initialize(resource:)
        @resource = resource
      end

      def self.mint_id(resource:)
        datacite_gen = DataciteGen.new(resource: resource)
        datacite_gen.mint_id
      end

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
        base_id = "#{APP_CONFIG[:identifier_service][:prefix]}/dryad.#{StashEngine::NoidState.mint}"
        "doi:#{base_id}"
      end

      # we are not reserving ahead with datacite, so just return the DOI
      def reserve_id(doi:)
        doi
      end

      # The method reserves a DOI if needed for a specified DOI or minting one from the pool.  (formerly?) used by Merritt
      # submission to be sure a (minted if needed) stash_engine_identifier exists with the ID filled in before doing fun stuff
      def ensure_identifier
        # ensure an existing identifier is reserved (if needed for EZID)
        return resource.identifier.to_s if resource&.identifier&.identifier.present?

        resource.ensure_identifier(mint_id)
      end

      def update_identifier_metadata!
        log_info("updating identifier landing page (#{landing_page_url}) and metadata for resource #{resource.id} (#{resource.identifier_str})")
        sp = Stash::Merritt::SubmissionPackage.new(resource: resource, packaging: nil)
        dc4_xml = sp.dc4_builder.contents
        update_metadata(dc4_xml: dc4_xml, landing_page_url: landing_page_url) unless resource.skip_datacite_update
      end

      def landing_page_url
        @landing_page_url ||= Rails.application.routes.url_helpers.show_url(resource.identifier_str)&.gsub(%r{^http://}, 'https://')
      end

      def log_info(message)
        Rails.logger.info("#{Time.now.utc.xmlschema} #{self.class}: #{message}")
      end

      def ping(identifier)
        get_doi(identifier, username: account, password: password, sandbox: sandbox)
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

      def id_params
        @id_params ||= APP_CONFIG[:identifier_service]
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

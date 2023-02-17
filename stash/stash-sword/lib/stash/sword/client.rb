require 'digest'
require 'uri'
require 'stash/sword/header_utils'
require 'stash/sword/log_utils'
require 'stash/sword/http_helper'
require 'stash/sword/sequence_io'
require 'logger'
require 'byebug'

module Stash
  module Sword
    class Client
      include HeaderUtils
      include LogUtils

      EOL = "\r\n".freeze

      attr_reader :collection_uri, :username, :password, :helper

      # Creates a new {Client} for the specified collection URI, with the specified credentials.
      #
      # @param collection_uri [URI, String] The collection URI
      # @param username [String] the username
      # @param password [String] the password
      # @param on_behalf_of [String, nil] the user for whom the original sword package was deposited on behalf of.
      #   Defaults to `username`.
      # @param logger [Logger, nil] the logger to use, or nil to use a default logger
      def initialize(collection_uri:, username:, password:, on_behalf_of: nil, logger: nil, helper: nil) # rubocop:disable Metrics/ParameterLists
        validate(collection_uri, password, username)
        @collection_uri = to_uri(collection_uri)
        @username = username
        @password = password
        @on_behalf_of = on_behalf_of || username
        @helper       = helper || HTTPHelper.new(username: username, password: password, user_agent: "stash-sword #{VERSION}", logger: logger)
        @logger       = logger || default_logger
      end

      # Creates a new resource for the specified DOI with the specified payload
      #
      # @param doi [String] the DOI
      # @param payload [String] the payload path
      # @param packaging [Packaging] the packaging (defaults to {Packaging::SIMPLE_ZIP})
      # @return [DepositReceipt] the deposit receipt
      def create(doi:, payload:, packaging: Packaging::SIMPLE_ZIP)
        logger.debug("Stash::Sword::Client.create(doi: #{doi}, payload: #{payload})")
        uri = collection_uri.to_s
        response = do_post(uri, payload, create_request_headers(payload, doi, packaging))
        receipt_from(response)
      rescue StandardError => e
        log_error(e)
        raise
      end

      # Updates a resource with a new payload
      #
      # @param edit_iri [URI, String] the Atom Edit-IRI
      # @param payload [String] the payload path
      # @param packaging [Packaging] the packaging (defaults to {Packaging::SIMPLE_ZIP})
      # @return [Integer] the response code (if the request succeeds)
      def update(edit_iri:, payload:, packaging: Packaging::SIMPLE_ZIP)
        logger.debug("Stash::Sword::Client.update(edit_iri: #{edit_iri}, payload: #{payload})")
        uri = to_uri(edit_iri).to_s
        response = do_put(uri, payload, packaging)
        logger.debug(to_log_msg(response))
        response.code # TODO: what if anything should we return here?
      rescue StandardError => e
        log_error(e)
        raise
      end

      private

      def validate(collection_uri, password, username)
        raise 'no collection URI provided' unless collection_uri
        raise 'no username provided' unless username
        raise 'no password provided' unless password
      end

      def receipt_from(response)
        logger.debug(to_log_msg(response))

        body = response.body.strip
        return DepositReceipt.parse_xml(body) unless body.empty?

        receipt_from_location(response)
      end

      def receipt_from_location(response)
        logger.debug('Desposit receipt not provided in SWORD response body')
        edit_iri = response.headers[:location]
        return nil unless edit_iri

        logger.debug("Retrieving deposit receipt from Location header Edit-IRI: #{edit_iri}")
        body = helper.get(uri: to_uri(edit_iri))
        return nil unless body

        DepositReceipt.parse_xml(body)
      end

      def do_post(uri, payload, headers)
        File.open(payload, 'rb') do |file|
          return helper.post(uri: uri, payload: file, headers: headers)
        end
      end

      def do_put(uri, payload, packaging)
        boundary        = "========#{Time.now.utc.to_i}=="
        stream          = stream_for(payload: File.open(payload, 'rb'), boundary: boundary, packaging: packaging)
        begin
          helper.put(uri: uri, headers: update_request_headers(stream, boundary), payload: stream)
        ensure
          stream.close
        end
      end

      def stream_for(payload:, boundary:, packaging:)
        content = []
        # strictly speaking, do we need an Atom <entry/> first?
        content << "--#{boundary}#{EOL}"
        update_mime_headers(payload, packaging).each { |k, v| content << "#{k}: #{v}#{EOL}" }
        content << EOL
        content << payload
        content << EOL
        content << "--#{boundary}--#{EOL}"

        logger.debug("Payload:\n\t#{content.map(&:to_s).join("\t")}")

        SequenceIO.new(content).binmode
      end

      def to_uri(url)
        ::XML::MappingExtensions.to_uri(url)
      end
      protected :to_uri

    end
  end
end

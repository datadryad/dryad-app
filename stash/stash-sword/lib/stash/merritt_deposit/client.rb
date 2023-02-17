require 'digest'
require 'uri'
require 'http'
# require 'stash/sword/header_utils'
# require 'stash/sword/log_utils'
# require 'stash/sword/http_helper'
# require 'stash/sword/sequence_io'
require 'logger'
require 'byebug'

module Stash
  module MerrittDeposit
    class Client
      # include HeaderUtils
      # include LogUtils

      EOL = "\r\n".freeze

      attr_reader :collection_uri, :username, :password

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
        @http         = HTTP.basic_auth(user: username, pass: password)
                          .timeout(connect: 60, read: 60).timeout(60).follow(max_hops: 10)

        # HTTPHelper.new(username: username, password: password, user_agent: "stash-sword #{VERSION}", logger: logger)
        @logger       = logger || default_logger
      end

      # Creates a new resource for the specified DOI with the specified payload
      #
      # @param doi [String] the DOI
      # @param payload [String] the checkm file path
      def create(doi:, payload:)
        logger.debug("Stash::MerrittDeposit::Client.create(doi: #{doi}, payload: #{payload})")
        profile = "#{collection_uri.to_s.split('/').last}_content"

        response = do_post(profile, payload, doi)
        byebug
        # do we need to check response for something here? Check additional codes or errors.
      rescue StandardError => e
        log_error(e)
        raise
      end

      # Updates a resource with a new payload
      #
      # @param edit_iri [URI, String] the Atom Edit-IRI
      # @param payload [String] the payload path
      def update(doi:, payload:)
        byebug
        logger.debug("Stash::Sword::MerrittDeposit.update(edit_iri: #{edit_iri}, payload: #{payload})")
        uri = to_uri(edit_iri).to_s
        response = do_put(uri, payload, packaging)
        logger.debug(to_log_msg(response))
        response.code # TODO: what if anything should we return here?
      rescue StandardError => e
        log_error(e)
        raise
      end

      private

      def base_url
        APP_CONFIG['merritt_base_url']
      end

      def validate(collection_uri, password, username)
        raise 'no collection URI provided' unless collection_uri
        raise 'no username provided' unless username
        raise 'no password provided' unless password
      end

      # The function of the receipt is to update the following fields in the resource:
      #         resource.download_uri = receipt.em_iri
      #         resource.update_uri = receipt.edit_iri

      # We no longer need an update_uri, since I think it's based on the DOI, which we can use directly.
      # The download_uri should be populated by the rake task which checks merritt for something finishing from the processing state.
      # There should no longer be a provisional complete state.


      # TODO: the update option may also want to include a primaryIdentifier which is the Merritt ARK
      def do_post(profile, payload, doi)
        # HTTP example with post HTTP.post("http://example.com/upload", form: { file: HTTP::FormData::File.new(io) })

        @http.post("#{base_url}/object/update",
                   form: {
                     file: HTTP::FormData::File.new(payload),
                     profile: profile,
                     localIdentifier: doi,
                     submitter: @on_behalf_of,
                     retainTargetURL: true,
                     responseForm: 'json'
                   })
      end

      # no more PUT/update requests in Merritt API
      # def do_put(uri, payload, packaging)
      #   boundary        = "========#{Time.now.utc.to_i}=="
      #   stream          = stream_for(payload: File.open(payload, 'rb'), boundary: boundary, packaging: packaging)
      #   begin
      #     helper.put(uri: uri, headers: update_request_headers(stream, boundary), payload: stream)
      #   ensure
      #     stream.close
      #   end
      # end

      def to_uri(url)
        ::XML::MappingExtensions.to_uri(url)
      end
      protected :to_uri

    end
  end
end

require 'digest'
require 'uri'
require 'http'
require 'logger'
require 'byebug'

module Stash
  module Repo

    class ResponseError < StandardError; end

    class Client
      include LogUtils

      EOL = "\r\n".freeze

      attr_reader :collection_uri, :username, :password, :logger

      # Creates a new {Client} for the specified collection URI, with the specified credentials.
      #
      # @param collection_uri [URI, String] The collection URI
      # @param username [String] the username
      # @param password [String] the password
      # @param on_behalf_of [String, nil] the user for whom the original dataset was deposited on behalf of.
      #   Defaults to `username`.
      # @param logger [Logger, nil] the logger to use, or nil to use a default logger
      def initialize(on_behalf_of: nil, logger: nil)
        collection_uri = APP_CONFIG[:repository][:endpoint]
        username = APP_CONFIG[:repository][:username]
        password = APP_CONFIG[:repository][:password]
        validate(collection_uri, password, username)
        @collection_uri = collection_uri
        @username = username
        @password = password
        @on_behalf_of = on_behalf_of || username
        @http         = HTTP.basic_auth(user: username, pass: password)
          .timeout(connect: 60, read: 60).timeout(60).follow(max_hops: 10)

        @logger       = logger || default_logger
      end

      # Creates a new resource for the specified DOI with the specified payload
      #
      # @param doi [String] the DOI
      # @param payload [String] the checkm file path
      def create(doi:, payload:, retries: 3)
        logger.debug("Stash::Repo::Client.create(doi: #{doi}, payload: #{payload})")
        profile = "#{collection_uri.to_s.split('/').last}_content"

        do_post(profile: profile, payload: payload, doi: doi, retries: retries)
      rescue StandardError => e
        log_error(e)
        raise
      end

      # Updates a new resource for the specified DOI with the specified payload
      #
      # @param doi [String] the DOI
      # @param payload [String] the checkm file path
      # @param download_uri [String] the download URI which merritt returns to us and contains the internal merritt ark
      def update(doi:, payload:, download_uri:, retries: 3)
        logger.debug("Stash::Repo::Client.update(doi: #{doi}, payload: #{payload}, download_uri: #{download_uri})")
        profile = "#{collection_uri.to_s.split('/').last}_content"
        ark = URI.decode_www_form_component(download_uri.split('/').last)

        do_post(profile: profile, payload: payload, doi: doi, ark: ark, retries: retries)
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

      # We do not need an update_uri, since it's based on the DOI, which we can use directly.
      # The download_uri should be populated by the merritt_status rake task when a dataset is submitted
      # There should no longer be a provisional complete state for the new way of submitting to merritt.
      def do_post(profile:, payload:, doi:, ark: nil, retries: 3)
        params = {
          file: HTTP::FormData::File.new(payload),
          profile: profile,
          localIdentifier: doi,
          submitter: @on_behalf_of,
          retainTargetURL: true,
          responseForm: 'json'
        }

        params[:primaryIdentifier] = ark if ark
        begin
          resp = @http.post("#{base_url}/object/update", form: params)
          raise ResponseError, "Merritt returned #{resp.code} for #{doi} while submitting" unless resp.code < 300

          begin
            json = JSON.parse(resp.body.to_s)
            logger.info("Merritt submission started for #{doi}:\n#{json}")
            json.to_s
          rescue JSON::ParserError
            raise ResponseError, "Merritt returned #{resp.code} for #{doi} while submitting, but the response was not JSON"
          end
        rescue HTTP::Error => e
          if (retries -= 1) > 0
            sleep 5
            retry
          end
          raise e
        end

        resp
      end

    end
  end
end

require 'digest'
require 'uri'
require 'stash/sword/header_utils'
require 'stash/sword/log_utils'
require 'stash/sword/http_helper'
require 'stash/sword/sequence_io'

module Stash
  module Sword
    class Client
      include HeaderUtils, LogUtils

      EOL = "\r\n".freeze

      attr_reader :collection_uri
      attr_reader :username
      attr_reader :password
      attr_reader :helper

      # Creates a new {Client} for the specified collection URI, with the specified credentials.
      #
      # @param collection_uri [URI, String] The collection URI
      # @param username [String] the username
      # @param password [String] the password
      # @param on_behalf_of [String, nil] the user for whom the original sword package was deposited on behalf of.
      #   Defaults to `username`.
      def initialize(collection_uri:, username:, password:, on_behalf_of: nil, helper: nil)
        raise 'no collection URI provided' unless collection_uri
        raise 'no username provided' unless username
        raise 'no password provided' unless password
        @collection_uri = to_uri(collection_uri)
        @username     = username
        @password     = password
        @on_behalf_of = on_behalf_of || username
        @helper       = helper || HTTPHelper.new(username: username, password: password, user_agent: "stash-sword #{VERSION}")
      end

      # Creates a new resource for the specified DOI with the specified zipfile
      #
      # @param doi [String] the DOI
      # @param zipfile [String] the zipfile path
      # @return [DepositReceipt] the deposit receipt
      def create(doi:, zipfile:)
        log.debug("Stash::Sword::Client.create(doi: #{doi}, zipfile: #{zipfile})")
        uri = collection_uri.to_s
        response = do_post(uri, zipfile, create_request_headers(zipfile, doi))
        receipt_from(response)
      rescue => e
        log_error(e)
        raise
      end

      # Updates a resource with a new zipfile
      #
      # @param edit_iri [URI, String] the Atom Edit-IRI
      # @param zipfile [String] the zipfile path
      def update(edit_iri:, zipfile:)
        log.debug("Stash::Sword::Client.update(edit_iri: #{edit_iri}, zipfile: #{zipfile})")
        uri = to_uri(edit_iri).to_s
        response = maybe_redirect(do_put(uri, zipfile))
        log.debug(response_to_log_msg(response))
        response.code # TODO: what if anything should we return here?
      rescue => e
        log_error(e)
        raise
      end

      private

      def maybe_redirect(response)
        return response unless [301, 302, 307].include?(response.code)
        log.debug(response_to_log_msg(response))
        log.debug("Response code #{response.code}; redirecting")
        response.follow_get_redirection
      end

      def receipt_from(response)
        log.debug(response_to_log_msg(response))

        body = response.body.strip
        return DepositReceipt.parse_xml(body) unless body.empty?

        receipt_from_location(response)
      end

      def receipt_from_location(response)
        log.debug('Desposit receipt not provided in SWORD response body')
        edit_iri = response.headers[:location]
        return nil unless edit_iri

        log.debug("Retrieving deposit receipt from Location header Edit-IRI: #{edit_iri}")
        body = helper.get(to_uri(edit_iri))
        return nil unless body

        DepositReceipt.parse_xml(body)
      end

      def do_post(uri, zipfile, headers)
        File.open(zipfile, 'rb') do |file|
          return helper.post(uri: uri, payload: file, headers: headers)
        end
      end

      def do_put(uri, zipfile)
        boundary        = "========#{Time.now.to_i}=="
        stream          = stream_for(zipfile: File.open(zipfile, 'rb'), boundary: boundary)
        begin
          return helper.put(uri: uri, headers: update_request_headers(stream, boundary), payload: stream)
        ensure
          stream.close
        end
      end

      def stream_for(zipfile:, boundary:)
        content = []
        # strictly speaking, do we need an Atom <entry/> first?
        content << "--#{boundary}#{EOL}"
        update_mime_headers(zipfile).each { |k, v| content << "#{k}: #{v}#{EOL}" }
        content << EOL
        content << zipfile
        content << EOL
        content << "--#{boundary}--#{EOL}"

        log.debug("Payload:\n\t#{content.map(&:to_s).join("\t")}")

        SequenceIO.new(content).binmode
      end

      def to_uri(url)
        ::XML::MappingExtensions.to_uri(url)
      end
      protected :to_uri

    end
  end
end

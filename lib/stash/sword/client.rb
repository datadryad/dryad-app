require 'digest'
require 'uri'
require 'stash/sword/header_utils'
require 'stash/sword/http_helper'
require 'stash/sword/sequence_io'

module Stash
  module Sword
    class Client
      include HeaderUtils

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

      def log
        ::Stash::Sword.log
      end
      protected :log

      # Creates a new resource for the specified DOI with the specified zipfile
      #
      # @param doi [String] the DOI
      # @param zipfile [String] the zipfile path
      # @return [DepositReceipt] the deposit receipt
      def create(doi:, zipfile:)
        log.debug("Stash::Sword::Client.create(doi: #{doi}, zipfile: #{zipfile})")
        warn "#{zipfile} may not be a zipfile" unless zipfile.downcase.end_with?('.zip')
        uri = collection_uri.to_s
        response = do_post(uri, zipfile, create_request_headers(zipfile, doi))
        receipt_from(response)
      rescue => e
        if e.respond_to?(:response)
          log.error(to_log_msg(e.response))
        else
          log.error('Unable to log response')
        end
        raise
      end

      # Updates a resource with a new zipfile
      #
      # @param se_iri [URI, String] the SWORD Edit IRI
      # @param zipfile [String] the zipfile path
      def update(se_iri:, zipfile:)
        log.debug("Stash::Sword::Client.update(se_iri: #{se_iri}, zipfile: #{zipfile})")
        warn "#{zipfile} may not be a zipfile" unless zipfile.downcase.end_with?('.zip')
        uri = to_uri(se_iri).to_s
        response = maybe_redirect(do_put(uri, zipfile))
        log.debug(to_log_msg(response))
        response.code # TODO: what if anything should we return here?
      rescue => e
        if e.respond_to?(:response)
          log.error(to_log_msg(e.response))
        else
          log.error('Unable to log response')
        end
        raise
      end

      private

      def maybe_redirect(response)
        return response unless [301, 302, 307].include?(response.code)
        log.debug(to_log_msg(response))
        log.debug("Response code #{response.code}; redirecting")
        response.follow_get_redirection
      end

      def receipt_from(response)
        log.debug(to_log_msg(response))

        body = response.body.strip
        return DepositReceipt.parse_xml(body) unless body.empty?

        edit_iri = response.headers[:location]
        return nil unless edit_iri

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
        content << "--#{boundary}--#{EOL}"
        SequenceIO.new(content).binmode
      end

      def to_log_msg(response)
        [
            '-----------------------------------------------------',
            "code: #{response.code}",
            'headers:',
            response.headers.map { |k, v| "\t#{k}:#{v}" }.join("\n"),
            "body:\n#{response.body}",
            '-----------------------------------------------------'
        ].join("\n")
      end
      protected :to_log_msg

      def to_uri(url)
        ::XML::MappingExtensions.to_uri(url)
      end
      protected :to_uri

    end
  end
end

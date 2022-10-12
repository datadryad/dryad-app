require 'net/http'
require 'rest-client'
require 'uri'
require 'stash/sword/log_utils'

module Stash
  module Sword
    # Utility class simplifying GET requests for HTTP/HTTPS resources.
    class HTTPHelper

      include LogUtils

      # The default number of redirects to follow before erroring out.
      DEFAULT_MAX_REDIRECTS = 5

      # The default number of seconds to allow before timing out.
      DEFAULT_TIMEOUT = 3300 # 55 minutes before timing out to go asynchronous

      # @return [String] the User-Agent string to send when making requests
      attr_accessor :user_agent

      # @return [Integer] the number of redirects to follow before erroring out
      attr_accessor :redirect_limit

      # @return [Integer] the number of seconds to allow before timing out
      attr_accessor :timeout

      # @return [String] the HTTP Basic Authentication username
      attr_reader :username

      # @return [String] the HTTP Basic Authentication password
      attr_reader :password

      # Creates a new `HTTPHelper`
      #
      # @param user_agent [String] the User-Agent string to send when making requests
      # @param redirect_limit [Integer] the number of redirects to follow before erroring out
      #   (defaults to {DEFAULT_MAX_REDIRECTS})
      # @param logger [Logger, nil] the logger to use, or nil to use a default logger
      # rubocop:disable Metrics/ParameterLists
      def initialize(user_agent:, username: nil, password: nil, redirect_limit: DEFAULT_MAX_REDIRECTS,
                     timeout: DEFAULT_TIMEOUT, logger: nil)
        @user_agent = user_agent
        @redirect_limit = redirect_limit
        @timeout = timeout
        @username = username
        @password = password
        @log = logger || default_logger
      end
      # rubocop:enable Metrics/ParameterLists

      # Gets the content of the specified URI as a string.
      # @param uri [URI] the URI to download
      # @param limit [Integer] the number of redirects to follow (defaults to {#redirect_limit})
      # @return [String] the content of the URI
      def get(uri:, limit: redirect_limit)
        do_get(uri, limit) do |success|
          # not 100% clear why we need an explicit return here; it
          # doesn't show up in unit tests but it does in example.rb
          return success.body
        end
      end

      # Posts the specified payload string to the specified URI.
      def post(uri:, payload:, headers: {}, limit: redirect_limit)
        do_post_or_put(method: :post, uri: uri, payload: payload, headers: headers, limit: limit, timeout: timeout)
      end

      # Puts the specified payload string to the specified URI.
      def put(uri:, payload:, headers: {}, limit: redirect_limit)
        do_post_or_put(method: :put, uri: uri, payload: payload, headers: headers, limit: limit, timeout: timeout)
      end

      private

      def default_headers
        {
          'User-Agent' => user_agent,
          'Content-Transfer-Encoding' => 'binary'
        }.freeze
      end

      def do_post_or_put(method:, uri:, payload:, headers:, limit:, timeout:) # rubocop:disable Metrics/ParameterLists
        options = request_options(headers, limit, method, payload, uri, timeout)
        log_hash(options)
        RestClient::Request.execute(**options)
      end

      # rubocop:disable Metrics/ParameterLists
      def request_options(headers, limit, method, payload, uri, timeout)
        options = {
          method: method,
          url: uri.to_s,
          payload: payload,
          headers: headers.merge(default_headers),
          max_redirects: limit,
          open_timeout: timeout,
          read_timeout: timeout
        }
        options[:user] = username if username
        options[:password] = password if password
        options
      end
      # rubocop:enable Metrics/ParameterLists

      # TODO: Consider rewriting with RestClient
      def do_get(uri, limit, &block)
        raise "Redirect limit (#{redirect_limit}) exceeded retrieving URI #{uri}" if limit <= 0

        req = Net::HTTP::Get.new(uri, 'User-Agent' => user_agent)
        req.basic_auth(username, password) if username && password
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
          http.request(req) do |response|
            case response
            when Net::HTTPSuccess
              yield(response)
            when Net::HTTPInformation, Net::HTTPRedirection
              do_get(redirect_uri_for(response, uri), limit - 1, &block)
            else
              raise "Error #{response.code}: #{response.message} retrieving URI #{uri}"
            end
          end
        end
      end

      def redirect_uri_for(response, original_uri)
        if response.is_a?(Net::HTTPInformation)
          original_uri
        else
          location = response['location']
          new_uri = URI(location)
          new_uri.relative? ? original_uri + location : new_uri
        end
      end
    end
  end
end

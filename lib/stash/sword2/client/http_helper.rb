require 'net/http'
require 'rest-client'
require 'uri'

module Stash
  module Sword2
    module Client
      # Utility class simplifying GET requests for HTTP/HTTPS resources.
      class HTTPHelper

        # The default number of redirects to follow before erroring out.
        DEFAULT_MAX_REDIRECTS = 5

        # @return [String] the User-Agent string to send when making requests
        attr_accessor :user_agent

        # @return [Integer] the number of redirects to follow before erroring out
        attr_accessor :redirect_limit

        # @return [String] the HTTP Basic Authentication username
        attr_reader :username

        # @return [String] the HTTP Basic Authentication password
        attr_reader :password

        # Creates a new `HTTPHelper`
        #
        # @param user_agent [String] the User-Agent string to send when making requests
        # @param redirect_limit [Integer] the number of redirects to follow before erroring out
        #   (defaults to {DEFAULT_MAX_REDIRECTS})
        def initialize(user_agent:, username: nil, password: nil, redirect_limit: DEFAULT_MAX_REDIRECTS)
          @user_agent     = user_agent
          @redirect_limit = redirect_limit
          @username       = username
          @password       = password
        end

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
          do_post_or_put(method: :post, uri: uri, payload: payload, headers: headers, limit: limit)
        end

        # Puts the specified payload string to the specified URI.
        def put(uri:, payload:, headers: {}, limit: redirect_limit)
          do_post_or_put(method: :put, uri: uri, payload: payload, headers: headers, limit: limit)
        end

        private

        def do_post_or_put(method:, uri:, payload:, headers:, limit:)
          options = {}
          options[:user] = username if username
          options[:password] = password if password

          all_headers = { 'User-Agent' => user_agent }
          all_headers.merge!(headers)

          RestClient::Request.execute(
            method: method,
            url: uri.to_s,
            payload: payload,
            headers: all_headers,
            max_redirects: limit,
            **options)
        end

        # TODO: Consider rewriting with RestClient
        def do_get(uri, limit, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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
            new_uri  = URI(location)
            new_uri.relative? ? original_uri + location : new_uri
          end
        end
      end
    end
  end
end

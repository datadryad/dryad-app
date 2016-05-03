require 'net/http'
require 'tempfile'
require 'uri'
require 'mime-types'

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

        # Creates a new `HTTPHelper`
        #
        # @param user_agent [String] the User-Agent string to send when making requests
        # @param redirect_limit [Integer] the number of redirects to follow before erroring out
        #   (defaults to {DEFAULT_MAX_REDIRECTS})
        def initialize(user_agent:, redirect_limit: DEFAULT_MAX_REDIRECTS)
          @user_agent     = user_agent
          @redirect_limit = redirect_limit
        end

        # Gets the content of the specified URI as a string.
        # @param uri [URI] the URI to download
        # @param limit [Integer] the number of redirects to follow (defaults to {#redirect_limit})
        # @return [String] the content of the URI
        def fetch(uri:, limit: redirect_limit)
          make_request(uri, limit) do |success|
            # not 100% clear why we need an explicit return here; it
            # doesn't show up in unit tests but it does in example.rb
            return success.body
          end
        end

        # Gets the content of the specified URI and saves it to a file. If no
        # file path is provided, saves it to a temporary file.
        # @param uri [URI] the URI to download
        # @param path [String] the path to save the download to (optional)
        # @return [String] the path to the downloaded file
        def fetch_to_file(uri:, path: nil, limit: redirect_limit)
          make_request(uri, limit) do |success|
            file = path ? File.new(path, 'w+') : Tempfile.new(['resync-client', ".#{extension_for(success)}"])
            open file, 'w' do |out|
              success.read_body { |chunk| out.write(chunk) }
            end
            return file.path
          end
        end

        private

        def make_request(uri, limit, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          fail "Redirect limit (#{redirect_limit}) exceeded retrieving URI #{uri}" if limit <= 0
          req = Net::HTTP::Get.new(uri, 'User-Agent' => user_agent)
          Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
            http.request(req) do |response|
              case response
                when Net::HTTPSuccess
                  block.call(response)
                when Net::HTTPInformation, Net::HTTPRedirection
                  make_request(redirect_uri_for(response, uri), limit - 1, &block)
                else
                  fail "Error #{response.code}: #{response.message} retrieving URI #{uri}"
              end
            end
          end
        end

        def extension_for(response)
          content_type = response['Content-Type']
          mime_type    = MIME::Types[content_type].first || MIME::Types['application/octet-stream'].first
          mime_type.preferred_extension || 'bin'
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

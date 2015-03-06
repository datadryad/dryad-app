require 'dash2/harvester/version'

module Dash2
  module Harvester

    # A harvesting client for a single repository
    class Client

      attr_reader :base_uri

      # Creates a new harvesting client for the given repository
      #
      # @param base_url [String] the base URL of the target repository
      # @raise [URI::InvalidURIError] if the base URL is invalid
      def initialize(base_url)
        @base_uri = URI.parse base_url
      end

      # TODO does this need to be tested directly?
      private
      def oai_client
        @oai_client ||= OAI::Client.new @base_url
      end

      private
      def base_url
        @base_url ||= @base_uri.to_s
      end
    end

  end
end

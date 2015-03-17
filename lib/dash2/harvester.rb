require 'uri'
require 'oai/client'

module Dash2
  module Harvester

    # Dir.glob(File.expand_path('../harvester/*.rb', __FILE__)).each{|rb_file| require(rb_file)}

    # print('Attempting to require from ' + File.basename(__FILE__, '.rb') + "\n")
    # print(Dir.glob(File.basename(__FILE__, '.rb') + "\n"))
    #
    # Dir.glob(File.basename(__FILE__, '.rb'), &method(:require_relative))

    print('Attempting to require from ' + File.expand_path('../harvester/*.rb', __FILE__) + "\n")
    Dir.glob(File.expand_path('../harvester/*.rb', __FILE__), &method(:require))

    # A harvesting client for a single repository
    class Client

      attr_reader :base_uri

      # Creates a new harvesting client for the given repository
      #
      # @param base_url [String] the base URL of the target repository
      # @raise [URI::InvalidURIError] if +base_url+ is invalid
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

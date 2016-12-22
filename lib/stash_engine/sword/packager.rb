module StashEngine
  module Sword
    class Packager
      attr_reader :resource
      attr_reader :tenant
      attr_reader :url_helpers
      attr_reader :request_host
      attr_reader :request_port

      def initialize(resource:, tenant:, url_helpers:, request_host:, request_port:)
        @resource = resource
        @tenant = tenant
        @url_helpers = url_helpers
        @request_host = request_host
        @request_port = request_port
      end

      # Creates a new zipfile package
      #
      # @return [StashEngine::Sword::Package] a {Package}
      def create_package
        raise NoMethodError, "#{self.class} should override #create_package to create a Sword::Package, but it doesn't"
      end
    end
  end
end

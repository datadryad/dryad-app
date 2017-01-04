module StashEngine
  module Sword
    class Packager
      attr_reader :resource_id
      attr_reader :tenant
      attr_reader :url_helpers
      attr_reader :request_host
      attr_reader :request_port

      def initialize(resource:, tenant:, url_helpers:, request_host:, request_port:)
        @resource_id = resource.id
        @tenant = tenant
        @url_helpers = url_helpers
        @request_host = request_host
        @request_port = request_port
      end

      def resource
        @resource ||= Resource.find(resource_id)
      end

      # Returns the title of the resource
      #
      # @return [String, nil] the title, or nil if the title cannot be determined
      def resource_title
        raise NoMethodError, "#{self.class} should override #create_package to return a title, but it doesn't"
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

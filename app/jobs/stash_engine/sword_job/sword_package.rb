module StashEngine
  module Sword
    class Package
      attr_reader :title
      attr_reader :doi
      attr_reader :zipfile
      attr_reader :resource_id
      attr_reader :sword_params
      attr_reader :request_host
      attr_reader :request_port

      # Creates a new {Package}
      #
      # @param title [String] The title of the dataset being submitted
      # @param doi [String] The DOI of the dataset being submitted
      # @param zipfile [String] The local path, on the server, of the zipfile to be submitted
      # @param resource_id [Integer] The ID of the resource being submitted
      # @param sword_params [Hash] Initialization parameters for `Stash::Sword::Client`.
      #   See the [stash-sword documentation](http://www.rubydoc.info/gems/stash-sword/Stash/Sword/Client#initialize-instance_method)
      #   for details.
      # @param request_host [String] The public hostname of the application UI. Used to generate links in the
      #   notification email.
      # @param request_port [Integer] The public-facing port of the application UI. Used to generate links in the
      #   notification email.
      def initialize(title:, doi:, zipfile:, resource_id:, sword_params:, request_host:, request_port:)
        @title = title
        @doi = doi
        @zipfile = zipfile
        @resource_id = resource_id
        @sword_params = sword_params
        @request_host = request_host
        @request_port = request_port
      end
    end
  end
end

require 'http'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# z = Stash::ZenodoReplicate::ZenodoConnection.new(resource: resource, path: '')

module Stash
  module ZenodoReplicate
    class ZenodoConnection
      def initialize(resource:, path:)
        @resource = resource
        @path = path

        @http = HTTP.timeout(connect: 30, read: 60).timeout(7200).follow(max_hops: 10)
      end

      # checks that can access API with token
      def validate_access
        r = @http.get("#{base_url}/api/deposit/depositions", params: param_merge)
        return true if r.status.success?
        false
      rescue HTTP::Error
        false
      end


      def new_deposition
        r = @http.post("#{base_url}/api/deposit/depositions", params: param_merge,
                       headers: {'Content-Type': 'application/json'},
                       json: {})
        # r.status.success?
        # resp = r.parse.with_indifferent_access
        # resp[:links]
        # resp[:files]
        # resp[:id]
        # resp[:metadata]
        # resp[:state]
      end

      private

      def param_merge(p={})
        { access_token: APP_CONFIG[:zenodo][:access_token]}.merge(p)
      end

      def base_url
        APP_CONFIG[:zenodo][:base_url]
      end

    end
  end
end
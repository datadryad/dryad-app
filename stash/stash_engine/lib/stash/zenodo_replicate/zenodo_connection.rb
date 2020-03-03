require 'http'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# z = Stash::ZenodoReplicate::ZenodoConnection.new(resource: resource, file_collection:)

module Stash
  module ZenodoReplicate

    class ZenodoError < StandardError; end

    class ZenodoConnection

      attr_reader :resource, :file_collection, :deposit_id, :links

      # for most actions in here, return the parsed out json and raise error if something not successful

      def initialize(resource:, file_collection:)
        @resource = resource
        @file_collection = file_collection

        @http = HTTP.timeout(connect: 30, read: 60).timeout(7200).follow(max_hops: 10)
      end

      # checks that can access API with token and return boolean
      def validate_access
        r = @http.get("#{base_url}/api/deposit/depositions", params: param_merge)
        return true if r.status.success?

        false
      rescue HTTP::Error
        false
      end

      # this creates a new deposit and adds metadata at the same time and returns the json response if successful
      def new_deposition
        mg = MetadataGenerator.new(resource: @resource)
        r = @http.post("#{base_url}/api/deposit/depositions", params: param_merge,
                                                              headers: { 'Content-Type': 'application/json' },
                                                              json: { metadata: mg.metadata })

        raise ZenodoError, "Zenodo response: #{r.status.code}" unless r.status.success?

        resp = r.parse.with_indifferent_access
        @deposit_id = resp[:id]
        @links = resp[:links]

        # state is unsubmitted at this point
        resp
      end

      def send_files
        path = @file_collection.path.to_s
        path << '/' unless path.end_with?('/')

        all_files = Dir["#{path}/**/*"]

        all_files.each do |f|
          short_fn = f[path.length..-1]
          r = @http.put("#{links[:bucket]}/#{ERB::Util.url_encode(short_fn)}",
                        params: param_merge,
                        body: File.open(f, 'rb'))

          resp = r.parse.with_indifferent_access
          # TODO: check the response digest against the known digest
        end
      end

      def get_files_info
        # right now this is mostly just used for internal testing
        r = @http.get(links[:bucket], params: param_merge)
        r.parse.with_indifferent_access
      end

      def publish
        r = @http.post(links[:publish], params: param_merge)
        r.parse.with_indifferent_access
      end

      private

      def param_merge(p = {})
        { access_token: APP_CONFIG[:zenodo][:access_token] }.merge(p)
      end

      def base_url
        APP_CONFIG[:zenodo][:base_url]
      end

    end
  end
end

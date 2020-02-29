require 'http'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# z = Stash::ZenodoReplicate::ZenodoConnection.new(resource: resource, path: '')

module Stash
  module ZenodoReplicate

    class ZenodoError < StandardError; end

    class ZenodoConnection

      attr_reader :resource, :path, :deposit_id, :links

      def initialize(resource:, path:)
        @resource = resource
        @path = path # the path to where files to upload are

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

      # this creates a new deposit and adds metadata at the same time
      def new_deposition
        mg = MetadataGenerator.new(resource: @resource)
        r = @http.post("#{base_url}/api/deposit/depositions", params: param_merge,
                                                              headers: { 'Content-Type': 'application/json' },
                                                              json: { metadata: mg.metadata })

        raise ZenodoError, "Zenodo response: #{r.status.code}" unless r.status.success?
        resp = r.parse.with_indifferent_access
        @deposit_id = resp[:id]
        @links = resp[:links]
        # state = unsubmitted
      end

      # may need to break this out into it's own class or at least track file deposits in a better way or check
      # MD5s or other things.
      def send_files
        path = @path.to_s
        path << '/' unless path.end_with?('/')

        all_files = Dir["#{path}/**/*"]

        all_files.each do |f|
          short_fn = f[path.length..-1]
          # PUT /api/files/<bucket-id>/<filename>
          resp = @http.put("#{links[:bucket]}/#{ERB::Util.url_encode(short_fn)}",
                           params: param_merge,
                           body: File.open(f, 'rb'))
        end
      end

      def get_files_info
        # right now this is mostly just used for internal testing
        resp = @http.get(links[:bucket], params: param_merge)
      end

      def publish
        # should be able to publish
        resp = @http.post(links[:publish], params: param_merge)
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

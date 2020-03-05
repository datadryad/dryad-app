require 'http'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# z = Stash::ZenodoReplicate::ZenodoConnection.new(resource: resource, file_collection:)
# The zenodo newversion seems to be editing the same deposition id
# 503933

module Stash
  module ZenodoReplicate

    class ZenodoError < StandardError; end

    class ZenodoConnection

      attr_reader :resource, :file_collection, :deposit_id, :links, :files

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

      # this creates a new deposit and adds metadata at the same time and returns the json response if successful, errors if already exists
      def new_deposition
        mg = MetadataGenerator.new(resource: @resource)
        r = @http.post("#{base_url}/api/deposit/depositions", params: param_merge,
                                                              headers: { 'Content-Type': 'application/json' },
                                                              json: { metadata: mg.metadata })

        resp = r.parse.with_indifferent_access

        raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp}" unless r.status.success?

        # {"status"=>400, "message"=>"Validation error.", "errors"=>[{"field"=>"metadata.doi", "message"=>"DOI already exists in Zenodo."}]}

        @deposit_id = resp[:id]
        @links = resp[:links]

        # state is unsubmitted at this point
        resp
      end

      # deposition_id is an integer that zenodo gives us on the first deposit
      def new_version_deposition(deposit_id:)
        # POST /api/deposit/depositions/123/actions/newversion
        mg = MetadataGenerator.new(resource: @resource)
        r = @http.post("#{base_url}/api/deposit/depositions/#{deposit_id}/actions/newversion", params: param_merge,
                       headers: { 'Content-Type': 'application/json' })
                       # json: { metadata: mg.metadata }

        resp = r.parse.with_indifferent_access

        raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp}" unless r.status.success?

        @deposit_id = resp[:id]
        @links = resp[:links]
        @files = resp[:files]

        # state is done ???
        resp
      end

      def put_metadata
        mg = MetadataGenerator.new(resource: @resource)
        r = @http.put(@links[:latest_draft], params: param_merge,
                       headers: { 'Content-Type': 'application/json' },
                       json: { metadata: mg.metadata })

        resp = r.parse.with_indifferent_access

        raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp}" unless r.status.success?

        # {"status"=>400, "message"=>"Validation error.", "errors"=>[{"field"=>"metadata.doi", "message"=>"DOI already exists in Zenodo."}]}

        @deposit_id = resp[:id]
        @links = resp[:links]

        # state is unsubmitted at this point, but metadata is updated
        resp

      end

      def get_by_deposition(deposit_id:)
        r = @http.get("#{base_url}/api/deposit/depositions/#{deposit_id}", params: param_merge,
                       headers: { 'Content-Type': 'application/json' })

        resp = r.parse.with_indifferent_access

        raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp}" unless r.status.success?

        @deposit_id = resp[:id]
        @links = resp[:links]
        @files = resp[:files]

        resp
      end

      def delete_files
        r = @http.get("#{base_url}/api/deposit/depositions/#{deposit_id}", params: param_merge,
                      headers: { 'Content-Type': 'application/json' })
        resp = r.parse.with_indifferent_access

        resp[:files].map do |f|
          r2 = @http.delete(f[:links][:download], params: param_merge, headers: { 'Content-Type': 'application/json' } )
          resp2 = r2.parse_with_indifferent_access
          raise ZenodoError, "Zenodo response: #{r2.status.code}\n#{resp2}" unless r.status.success?
        end

        @files = [] # now it's empty

        r = @http.get("#{base_url}/api/deposit/depositions/#{deposit_id}", params: param_merge,
                      headers: { 'Content-Type': 'application/json' })
        resp = r.parse.with_indifferent_access
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

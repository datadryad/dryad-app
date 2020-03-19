require 'http'
require 'stash/zenodo_replicate/zenodo_connection'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# z = Stash::ZenodoReplicate::ZenodoConnection.new(resource: resource, file_collection:)
# The zenodo newversion seems to be editing the same deposition id
# 503933

module Stash
  module ZenodoReplicate
    class Files

      attr_reader :resource, :file_collection, :deposition_id, :links, :files

      def initialize(resource:, file_collection:)
        @resource = resource
        @file_collection = file_collection
        @zenodo_files = nil
      end

      def delete_files
        resp = standard_request(:get, "#{base_url}/api/deposit/depositions/#{deposition_id}")

        resp[:files].map do |f|
          standard_request(:delete, f[:links][:download])
        end

        standard_request(:get, "#{base_url}/api/deposit/depositions/#{deposition_id}")
      end

      def send_files
        path = @file_collection.path.to_s
        path << '/' unless path.end_with?('/')

        all_files = Dir["#{path}/**/*"]

        all_files.each do |f|
          short_fn = f[path.length..-1]
          resp = standard_request(:put, "#{links[:bucket]}/#{ERB::Util.url_encode(short_fn)}", body: File.open(f, 'rb'))

          # TODO: check the response digest against the known digest
        end
      end

      def get_files_info
        # right now this is mostly just used for internal testing
        standard_request(:get, links[:bucket])
      end
    end
  end
end

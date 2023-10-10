# :nocov:
require 'cgi'

module Tasks
  module DevOps
    module DownloadUri

      def self.update_from_file(file_path:)
        File.readlines(file_path).each do |line|
          parts = line.strip.split('|')
          update(doi: parts[0], old_ark: parts[1], new_ark: parts[2])
        end
      end

      def self.update(doi:, old_ark:, new_ark:)
        my_id = StashEngine::Identifier.where(identifier: doi[4..]).first
        return if my_id.nil?

        resources = my_id.resources.where('download_uri LIKE ?', "%#{CGI.escape(old_ark)}")

        resources.each do |resource|
          old_dl_uri = resource.download_uri
          # extract the part of the path with the old merrritt collection name and replace it with /cdl_dryad/
          collection_match = resource.update_uri.match(%r{39001/[^/]+/[^/]+/([^/]+)/doi})
          new_update = (if collection_match.present?
                          resource.update_uri.gsub(collection_match[1], '/cdl_dryad/')
                        else
                          resource.update_uri
                        end)
          new_dl = resource.download_uri.gsub(CGI.escape(old_ark), CGI.escape(new_ark))
          resource.record_timestamps = false # prevents updated_at from being changed automatically
          resource.update!(download_uri: new_dl, update_uri: new_update)
          puts "Resource: #{resource.id} download_uri updated from #{old_dl_uri} to #{resource.download_uri}"
        end
      end
    end
  end
end
# :nocov:

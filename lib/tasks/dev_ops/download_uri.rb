require 'cgi'

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
        resource.update!(download_uri: resource.download_uri.gsub(CGI.escape(old_ark), CGI.escape(new_ark)))
        puts "Resource: #{resource.id} download_uri updated to #{resource.download_uri}"
      end
    end
  end
end

require 'stash/compressed'

module Tasks
  module Compressed
    module Info

      # maps into container_contents format, using appropriate compressed processor, eliminates directory entries and returns array of hashes
      def self.files(db_file:)
        entries =
          if db_file.upload_file_name.downcase.end_with?('.zip')
            zip_info = Stash::Compressed::ZipInfo.new(presigned_url: db_file.merritt_s3_presigned_url)
            zip_info.entries_with_fallback
          elsif db_file.upload_file_name.downcase.end_with?('.tar.gz', '.tgz')
            tar_gz_info = Stash::Compressed::TarGz.new(presigned_url: db_file.merritt_s3_presigned_url)
            tar_gz_info.entries_with_fallback
          else
            raise Stash::Compressed::Error, "Unknown file type for #{db_file.upload_file_name}"
          end

        output = []
        entries.each do |entry|
          next if entry[:file_name].end_with?('/') # skip directories

          output << { path: entry[:file_name], size: entry[:uncompressed_size],
                      mime_type: Rack::Mime.mime_type(File.extname(entry[:file_name])) }
        end

        output
      end
    end
  end
end

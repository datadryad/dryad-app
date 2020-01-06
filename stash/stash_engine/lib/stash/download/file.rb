require_relative 'base'

# this doesn't add functionality to base class.  It would have added something for Merritt Express file downloads, but
# Merritt Express doesn't support file downloads from all versions right now so no using it.

module Stash
  module Download
    class File < Base

      attr_accessor :file

      # this downloads a file as a stream from Merritt express
      def download(file:)
        @file = file
        # needs to be set for tracking downloads
        @resource_id = @file&.resource&.id
        @file_id = @file.id

        stream_response(url: file.merritt_express_url, tenant: file.resource.tenant, filename: disposition_filename)
      end

      # tries to make the disposition and we can do it directly from the filename since we know it
      # url used for consistency
      def disposition_filename
        # use the ruby file class not the Download::File class below
        ::File.basename(@file.upload_file_name)
      end
    end
  end
end

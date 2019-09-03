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
        # StashEngine::CounterLogger.version_download_hit(request: cc.request, resource: resource)
        stream_response(url: file.merritt_express_url, tenant: file.resource.tenant)
      end

      # tries to make the disposition and we can do it directly from the filename since we know it
      # url used for consistency
      def disposition_filename
        "attachment; filename=\"#{::File.basename(@file.upload_file_name)}\""
      end

      # this one overrides the base one for now because Merritt is slow to return a HEAD request on large files.
      # See if I can just populate it from the file in the database
      #
      # to stream the response through this UI instead of redirecting, keep login and other stuff private
      # rubocop:disable Metrics/AbcSize
      def stream_response(url:, tenant:)
        # get original header info from http headers
        client = Stash::Repo::HttpClient.new(tenant: tenant, cert_file: APP_CONFIG.ssl_cert_file).client

        # headers = client.head(url, follow_redirect: true)

        content_type = file.upload_content_type
        content_length = file.upload_file_size.nil? || file.upload_file_size == 0 ? '' : file.upload_file_size
        content_disposition = "attachment; filename=\"#{file.upload_file_name}\""
        cc.response.headers['Content-Type'] = content_type if content_type
        cc.response.headers['Content-Disposition'] = content_disposition
        cc.response.headers['Content-Length'] = content_length
        # cc.response.headers['Transfer-Encoding'] = 'chunked'
        # transfer encoding chunked makes it fail with zero bytes
        cc.response.headers['Last-Modified'] = Time.now.utc.httpdate
        cc.response_body = Stash::Streamer.new(client, url)
      end
      # rubocop:enable Metrics/AbcSize

    end
  end
end

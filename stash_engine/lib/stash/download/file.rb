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
        ::File.basename(@file.upload_file_name)
      end

      # this one overrides the base one for now because Merritt is slow to return a HEAD request on large files.
      # See if I can just populate it from the file in the database
      #
      # to stream the response through this UI instead of redirecting, keep login and other stuff private
      # rubocop:disable Metrics/AbcSize
      def stream_response(url:, tenant:)
        # client = Stash::Repo::HttpClient.new(tenant: tenant, cert_file: APP_CONFIG.ssl_cert_file).client

        # url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
        url = url.gsub('://', "://#{tenant.repository.username}:#{tenant.repository.password}")

        cc.request.env['rack.hijack'].call
        stream = cc.request.env['rack.hijack_io']

        Thread.new do
          # TODO: set more options for download stream
          remote_file = Down::Wget.open(url)
          send_headers(stream: stream, header_obj: remote_file.data[:headers], filename: disposition_filename)
          send_stream(out_stream: stream, in_stream: remote_file)
        end

        cc.response.close
      end
      # rubocop:enable Metrics/AbcSize

    end
  end
end

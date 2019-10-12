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
        # dl_url = 'https://images-assets.nasa.gov/image/PIA22935/PIA22935~orig.jpg'
        # get original header info from http headers
        client = Stash::Repo::HttpClient.new(tenant: tenant, cert_file: APP_CONFIG.ssl_cert_file).client

        # set up header variables
        # content_length = file.upload_file_size.nil? || file.upload_file_size == 0 ? '' : file.upload_file_size
        content_length = nil
        content_type = file.upload_content_type
        content_disposition = "attachment; filename=\"#{file.upload_file_name}\""

        # set up headers
        cc.response.headers['Content-Type'] = content_type if content_type
        cc.response.headers['Content-Disposition'] = content_disposition
        cc.response.headers['Content-Length'] = content_length unless content_length.blank?
        # cc.response.headers['Transfer-Encoding'] = 'chunked'
        # messes it up

        cc.response.headers['X-Accel-Buffering'] = 'no'
        cc.response.headers['Cache-Control'] = 'no-cache'
        cc.response.headers['Last-Modified'] = Time.zone.now.ctime.to_s

        # rack hijack takes a proc to run and in another thread so it frees web server thread for normal short requests
        cc.response.headers['rack.hijack'] = proc do |stream|
          stream.autoclose = false
          # stream.sync = true

          Thread.new do
            # chunk_size = 1024 * 1024 # 1 MB
            begin
              client = Stash::Repo::HttpClient.new(tenant: tenant, cert_file: APP_CONFIG.ssl_cert_file).client
              client.receive_timeout = 7200
              client.send_timeout = 3600
              client.connect_timeout = 7200
              client.keep_alive_timeout = 3600
              client.get_content(url) do |chunk|
                stream << chunk #.force_encoding('UTF-8') # may be required for webrick
              end
            rescue StandardError => ex
              cc.logger.error("while downloading #{ex}")
            ensure
              stream.close
            end
          end
        end
        cc.head :ok
      end
      # rubocop:enable Metrics/AbcSize

    end
  end
end

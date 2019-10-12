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
        dl_url = 'https://images-assets.nasa.gov/image/PIA22935/PIA22935~orig.jpg'
        # get original header info from http headers
        # client = Stash::Repo::HttpClient.new(tenant: tenant, cert_file: APP_CONFIG.ssl_cert_file).client

        # set up header variables
        # content_length = file.upload_file_size.nil? || file.upload_file_size == 0 ? '' : file.upload_file_size
        content_length = nil
        content_type = file.upload_content_type
        content_disposition = "attachment; filename=\"#{file.upload_file_name}\""

        # set up headers
        cc.response.headers['Content-Type'] = content_type if content_type
        cc.response.headers['Content-Disposition'] = content_disposition
        cc.response.headers['Content-Length'] = content_length unless content_length.blank?

        cc.response.headers["X-Accel-Buffering"] = "no"
        cc.response.headers["Cache-Control"] = "no-cache"
        cc.response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

        # rack hijack takes a proc to run and in another thread so it frees web server thread for normal short requests
        cc.response.headers["rack.hijack"] = proc do |stream|

          Thread.new do
            chunk_size = 1024 * 1024 # 1 MB
            begin
              # see https://twin.github.io/httprb-is-great/ or https://github.com/httprb/http/wiki
              http = HTTP.timeout(connect: 3000, read: 3000, write: 1500).timeout(3000)
                         .basic_auth(user: tenant.repository.username, pass: tenant.repository.password)
              response = http.get(url)
              while true
                chunk = response.body.readpartial(chunk_size)
                break if chunk.nil?
                stream.write(chunk)
                # stream.write(chunk.force_encoding("UTF-8")) # I don't know why this is necessary, maybe only in webrick
              end
            rescue HTTP::Error => ex
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

require 'logger'
require 'http'
require 'down'
require 'down/wget'

# helpful about URL streaming https://web.archive.org/web/20130310175732/http://blog.sparqcode.com/2012/02/04/streaming-data-with-rails-3-1-or-3-2/
# https://stackoverflow.com/questions/3507594/ruby-on-rails-3-streaming-data-through-rails-to-client
module Stash
  module Download

    class MerrittResponseError < StandardError
    end

    # this is essentially an abstract class for version and file downloads to share common methods
    class Base
      attr_reader :cc

      def initialize(controller_context:)
        @cc = controller_context
      end

      # to stream the response through this UI instead of redirecting, keep login and other stuff private
      def stream_response(url:, tenant:)
        # get original header info from http headers
        client = Stash::Repo::HttpClient.new(tenant: tenant, cert_file: APP_CONFIG.ssl_cert_file).client

        headers = client.head(url, follow_redirect: true)

        content_type = headers.http_header['Content-Type'].try(:first)
        content_length = headers.http_header['Content-Length'].try(:first) || ''
        content_disposition = disposition_filename
        cc.response.headers['Content-Type'] = content_type if content_type
        cc.response.headers['Content-Disposition'] = content_disposition
        cc.response.headers['Content-Length'] = content_length
        cc.response.headers['Last-Modified'] = Time.now.utc.httpdate
        cc.response_body = Stash::Streamer.new(client, url)
      end

      def self.log_warning_if_needed(error:, resource:)
        return unless Rails.env.development?
        msg = "MerrittResponseError checking sync/async download for resource #{resource.id} updated at #{resource.updated_at}"
        backtrace = error.respond_to?(:backtrace) && error.backtrace ? error.backtrace.join("\n") : ''
        Rails.logger.warn("#{msg}: #{error.class}: #{error}\n#{backtrace}")
      end

      # these send methods are the streaming methods for a 'rack.hijack',

      def send_headers(stream:, header_obj:, filename:)
        Rails.logger.warn('started headers')
        headers = [ 'HTTP/1.1 200 OK' ]
        headers_to_keep = %w[Content-Type content-type Content-Length content-length ETag]
        heads = header_obj.slice(headers_to_keep)
        heads.merge( 'Content-Disposition'  => "attachment; filename=\"#{filename}\"",
                     'X-Accel-Buffering'    => 'no',
                     'Cache-Control'        => 'no-cache',
                     'Last-Modified'        => Time.zone.now.ctime.to_s )
        heads.each_pair { |k,v| headers.push("#{k}: #{v}")  }

        stream.write(headers.map { |header| header + "\r\n" }.join)
        Rails.logger.warn(headers.map { |header| header + "\r\n" }.join)
        stream.write("\r\n")
        stream.flush
      rescue StandardError => ex
        Rails.logger.warn("HEADER ERROR: #{ex}")
        stream.close
        raise
      end

      def send_stream(out_stream:, in_stream:)
        chunk_size = 1024 * 1024
        begin
          until in_stream.eof?
            out_stream.write(in_stream.read(chunk_size))
          end
        rescue StandardError => ex
          cc.logger.error("while streaming: #{ex}")
          cc.logger.error("while streaming: #{ex.backtrace}")
        ensure
          out_stream.close
          in_stream.close
        end
      end


    end
  end
end

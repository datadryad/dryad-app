require 'logger'
require 'http'
require 'down'
require 'down/wget'
require 'zaru'

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

      # this is a method that should be overridden

      # rubocop:disable Metrics/AbcSize
      def stream_response(url:, tenant:, filename:, read_timeout: 30)
        cc.request.env['rack.hijack'].call
        stream = cc.request.env['rack.hijack_io']

        # If the number of downloads becomes outrageous then we may need to have a limited thread pool, throttle individual
        # downloads or throttle overall requests to download from individual IP addresses or something else.
        Thread.new do
          # I believe these timeouts are reasonable for this type of read since Merritt Express should respond quickly
          # and doesn't need to assemble files into a zipe file like the full version download does.
          # We don't want to hold dead download threads open too long for resource and network reasons.
          remote_file = Down::Wget.open(url,
                                        http_user: tenant.repository.username,
                                        http_password: tenant.repository.password,
                                        max_redirect: 10,  # Merritt seems to love as many redirects as possible
                                        dns_timeout: 2,
                                        connect_timeout: 2,
                                        read_timeout: read_timeout)
          send_headers(stream: stream, header_obj: remote_file.data[:headers], filename: filename)
          send_stream(out_stream: stream, in_stream: remote_file)
        end
        cc.response.close
      end
      # rubocop:enable Metrics/AbcSize

      # these send methods are the streaming methods for a 'rack.hijack',
      def send_headers(stream:, header_obj:, filename:)
        out_headers = [ 'HTTP/1.1 200 OK' ]

        # keep some heads from this request and write them over to the outgoing headers
        heads = header_obj.slice(%w[Content-Type content-type Content-Length content-length ETag])
        heads.each_pair { |k,v| out_headers.push("#{k}: #{v}")  }

        # add these headers
        out_headers +=
            ["Content-Disposition: attachment; filename=\"#{filename}\"",
             'X-Accel-Buffering: no',
             'Cache-Control: no-cache',
             "Last-Modified: #{Time.zone.now.ctime.to_s}" ]

        stream.write(out_headers.map { |header| header + "\r\n" }.join)
        stream.write("\r\n")
        stream.flush
      rescue StandardError => ex
        Rails.logger.error("Error writing header: #{ex}")
        stream.close
        raise ex
      end

      def send_stream(out_stream:, in_stream:)
        chunk_size = 1024 * 1024
        begin
          until in_stream.eof?
            out_stream.write(in_stream.read(chunk_size))
          end
        rescue StandardError => ex
          cc.logger.error("Error while streaming: #{ex}")
          cc.logger.error("Error while streaming: #{ex.backtrace}")
        ensure
          out_stream.close
          in_stream.close
        end
      end
      # end methods for 'rack.hijack'

    end
  end
end

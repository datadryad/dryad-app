require 'logger'
require 'http'
require 'zaru'
require 'active_support'
require 'pry-remote'
require 'tempfile'

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
      def stream_response(url:, tenant:, filename:, read_timeout: 30)
        cc.request.env['rack.hijack'].call
        user_stream = cc.request.env['rack.hijack_io']

        # If the number of downloads becomes outrageous then we may need to have a limited thread pool, throttle individual
        # downloads or throttle overall requests to download from individual IP addresses or something else.
        Thread.new do
          # I believe these timeouts are reasonable for this type of read since Merritt Express should respond quickly
          # and doesn't need to assemble files into a zipe file like the full version download does.
          # We don't want to hold dead download threads open too long for resource and network reasons.

          begin
            http = HTTP.timeout(connect: 30, read: read_timeout).timeout(7200)
                  .basic_auth(user: tenant.repository.username, pass: tenant.repository.password)
                  # .persistent(URI.join(url, '/').to_s)
            merritt_response = http.get(url)

            send_headers(stream: user_stream, header_obj: merritt_response.headers.to_h, filename: filename)
            send_stream(merritt_stream: merritt_response, user_stream: user_stream)
          rescue StandardError => ex
            cc.logger.error("Error opening merritt URL: #{ex}")
          end
        end
        cc.response.close
      end

      # these send methods are the streaming methods for a 'rack.hijack',
      def send_headers(stream:, header_obj:, filename:)
        out_headers = ['HTTP/1.1 200 OK']

        # keep some heads from this request and write them over to the outgoing headers
        # heads = header_obj.slice('Content-Type', 'content-type', 'Content-Length', 'content-length', 'ETag')
        # heads.each_pair { |k, v| out_headers.push("#{k}: #{v}") }

        # add these headers
        out_headers +=
          ["Content-Disposition: attachment; filename=\"#{filename}\"",
           'X-Accel-Buffering: no',
           'Cache-Control: no-cache',
           "Last-Modified: #{Time.zone.now.ctime}"]

        stream.write(out_headers.map { |header| header + "\r\n" }.join)
        stream.write("\r\n")
        stream.flush
      rescue StandardError => ex
        Rails.logger.error("Error writing header: #{ex}")
        stream.close
        raise ex
      end

      def send_stream(user_stream:, merritt_stream:)
        begin
          # use this file to write contents of the stream
          write_file = Tempfile.create('dl_file', Rails.root.join('uploads')).binmode
          write_file.flock(::File::LOCK_NB|::File::LOCK_SH)
          write_file.sync = true

          # use this file object which is the same underlying file as above, but code ensures it doesn't
          # read past the end of what has been written so far
          read_file = ::File.open(write_file, 'r')

          write_thread = Thread.new do
            # this only modifies the write file with contents of merritt stream
            save_to_file(merritt_stream: merritt_stream, write_file: write_file)
          end

          read_thread = Thread.new do
            # this only modifies the user stream based on the contents of read file.  The other other
            # objects are only read or have state checked.  Ensures it doesn't read past the end of content.
            stream_from_file(read_file: read_file, write_file: write_file, user_stream: user_stream)
          end

          write_thread.join
          read_thread.join

        rescue StandardError => ex
          cc.logger.error("Error while streaming: #{ex}")
          cc.logger.error("Error while streaming: #{ex.backtrace}")
        ensure
          user_stream&.close unless user_stream&.closed?
          # merritt_stream&.close unless merritt_stream&.closed?
          read_file&.close unless read_file&.closed?
          write_file&.close unless write_file&.closed?
          ::File.unlink(write_file.path) if ::File.exist?(write_file.path)
        end
      end

      def save_to_file(merritt_stream:, write_file:)
        chunk_size = 1024 * 512 # 512k

        while (chunk = merritt_stream.readpartial(chunk_size))
          write_file.write(chunk)
        end
      ensure
        write_file.close
      end

      def stream_from_file(read_file:, write_file:, user_stream:)
        read_chunk_size = 1024 * 16 # 16k

        until read_file.closed?
          while (write_file.closed? && !read_file.closed? ) || ( read_file.pos + read_chunk_size < write_file.pos )
            data = read_file.read(read_chunk_size)

            user_stream.write(data)
            if read_file.eof?
              read_file.close
              break
            end
          end
          # no data to read right now, so wait a bit, if error read file should eventually close
          sleep(2)
        end

      ensure
        read_file.close unless read_file.closed?
      end
    end
  end
end

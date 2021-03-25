require 'logger'
require 'http'
require 'stash/download'
require 'zaru'
require 'active_support'
require 'tempfile'
require 'fileutils'
require 'byebug'

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
        @download_history = nil
      end

      # this is a method that should be overridden
      # rubocop:disable Metrics/AbcSize
      def stream_response(url:, tenant:, filename:, read_timeout: 30)
        cc.request.env['rack.hijack'].call
        user_stream = cc.request.env['rack.hijack_io']

        # If the number of downloads becomes outrageous then we may need to have a limited thread pool, throttle individual
        # downloads or throttle overall requests to download from individual IP addresses or something else.
        Thread.new do
          # I believe these timeouts are reasonable for this type of read since Merritt Express should respond quickly
          # and doesn't need to assemble files into a zip file like the full version download does.
          # We don't want to hold dead download threads open too long for resource and network reasons.

          http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
            .timeout(connect: 30, read: read_timeout).timeout(3.hours.to_i).follow(max_hops: 10)
            .basic_auth(user: tenant.repository.username, pass: tenant.repository.password)
          # .persistent(URI.join(url, '/').to_s)
          merritt_response = http.get(url)

          send_headers(stream: user_stream, header_obj: merritt_response.headers.to_h, filename: filename)
          send_stream(merritt_stream: merritt_response, user_stream: user_stream)
        rescue StandardError => e
          cc.logger.error("Error opening merritt URL: #{e}")

        end
        cc.response.close
      end
      # rubocop:enable Metrics/AbcSize

      # these send methods are the streaming methods for a 'rack.hijack',
      def send_headers(stream:, header_obj:, filename:)
        out_headers = ['HTTP/1.1 200 OK']

        # keep some heads from this request and write them over to the outgoing headers
        heads = header_obj.slice('Content-Type', 'content-type', 'Content-Length', 'content-length', 'ETag')
        heads.each_pair { |k, v| out_headers.push("#{k}: #{v}") }

        # add these headers
        out_headers +=
          ["Content-Disposition: attachment; filename=\"#{filename}\"",
           'X-Accel-Buffering: no',
           'Cache-Control: no-cache',
           "Last-Modified: #{Time.zone.now.ctime}"]

        stream.write(out_headers.map { |header| "#{header}\r\n" }.join)
        stream.write("\r\n")
        stream.flush
      rescue StandardError => e
        Rails.logger.error("Error writing header: #{e}")
        stream.close
        raise e
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def send_stream(user_stream:, merritt_stream:)
        # use this file to write contents of the stream
        FileUtils.mkdir_p(Rails.root.join('uploads')) # ensures this file is created if it doesn't exist, needed mostly for tests
        write_file = Tempfile.create('dl_file', Rails.root.join('uploads')).binmode
        write_file.flock(::File::LOCK_NB | ::File::LOCK_SH)
        write_file.sync = true

        # use this file object which is the same underlying file as above, but code ensures it doesn't
        # read past the end of what has been written so far
        read_file = ::File.open(write_file, 'r')

        @download_canceled = false

        write_thread = Thread.new do
          # tracking downloads needs to happen in the threads
          # This class is gone since no longer used to track downloads
          # @download_history = StashEngine::DownloadHistory.mark_start(ip: cc.request.remote_ip, user_agent: cc.request.user_agent,
          #                                                            resource_id: @resource_id, file_id: @file_id)
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
      rescue StandardError => e
        cc.logger.error("Error while streaming: #{e}")
        cc.logger.error("Error while streaming: #{e.backtrace}")
      ensure
        user_stream&.close unless user_stream&.closed?
        # merritt_stream&.close unless merritt_stream&.closed?
        read_file&.close unless read_file&.closed?
        write_file&.close unless write_file&.closed?
        ::File.unlink(write_file&.path) if ::File.exist?(write_file&.path)
        # class no longer exists to track history, and we're really not using this class anymore -- remants before presigned download urls
        # StashEngine::DownloadHistory.mark_end(download_history: @download_history) unless @download_history.nil?
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def save_to_file(merritt_stream:, write_file:)
        chunk_size = 1024 * 512 # 512k

        while (chunk = merritt_stream.readpartial(chunk_size))
          write_file.write(chunk)
          break if @download_canceled
        end
      rescue EOFError => e
        # I believe Ruby has this error with certain kinds of IO objects such as StringIO in testing, but seems to have written
        # the chunk, anyway.  But if it does happen I guess it's all fine, the stream is done and time to close it anyway
        # with the ensure.  Doesn't seem to happen with the HTTP library.
        # https://github.com/ohler55/ox/issues/7
        cc.logger.info("EoF reached in Merritt Stream: #{e}")
      ensure
        write_file.close unless write_file.closed?
      end

      def stream_from_file(read_file:, write_file:, user_stream:)
        read_chunk_size = 1024 * 16 # 16k

        until read_file.closed?
          while (write_file.closed? && !read_file.closed?) || (read_file.pos + read_chunk_size < write_file.pos)
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
        user_stream.close unless user_stream.closed?
        @download_canceled = true # set user download canceled (finished) to true in shared state to notify other thread to terminate its download
      end

    end
  end
end

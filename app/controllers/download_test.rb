require 'http'
require 'down'

class DownloadTestController < ApplicationController

  def stream1
    url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
    response.headers['Content-Type'] = 'image/tiff'
    response.headers['Content-Disposition'] = 'attachment; filename="funn.tif"'
    response.headers["X-Accel-Buffering"] = 'no'
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

    response.headers["rack.hijack"] = proc do |stream|
      Thread.new do
        begin
          response = HTTP.get(url)
          response.body.each do |chunk|
            stream.write(chunk)
          end
        rescue HTTP::Error => ex
          logger.error("while streaming: #{ex}")
          logger.error("while streaming: #{ex.backtrace.join("\n")}")
        ensure
          stream.close
        end
      end
    end
    head :ok
  end

  def stream2
    url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
    response.headers['Content-Type'] = 'image/tiff'
    response.headers['Content-Disposition'] = 'attachment; filename="funn.tif"'
    response.headers["X-Accel-Buffering"] = 'no'
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

    response.headers["rack.hijack"] = proc do |stream|

      Thread.new do
        chunk_size = 1024 * 1024
        begin
          remote_file = Down.open(url, rewindable: false)
          until remote_file.eof?
            stream.write(remote_file.read(chunk_size))
          end
        rescue StandardError => ex
          logger.error("while streaming: #{ex}")
          logger.error("while streaming: #{ex.backtrace.join("\n")}")
        ensure
          stream.close
        end
      end
    end
    head :ok
  end

end
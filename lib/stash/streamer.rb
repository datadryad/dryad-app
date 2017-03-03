module Stash
  class Streamer
    def initialize(url)
      @url = url
    end

    def each
      client = HTTPClient.new
      client.receive_timeout = 7200
      client.send_timeout = 3600
      client.connect_timeout = 7200
      client.keep_alive_timeout = 3600

      client.get_content(@url) { |chunk|
        yield chunk
      }
    end
  end
end
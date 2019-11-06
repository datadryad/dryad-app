module Stash
  class Streamer
    def initialize(http_client, url)
      @http_client = http_client
      @http_client.receive_timeout = 7200
      @http_client.send_timeout = 3600
      @http_client.connect_timeout = 7200
      @http_client.keep_alive_timeout = 3600
      @url = url
    end

    def each
      @http_client.get_content(@url) do |chunk|
        yield chunk
      end
    end
  end
end

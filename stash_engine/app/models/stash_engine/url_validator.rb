require 'httpclient'

module StashEngine
  class UrlValidator

    attr_reader :mime_type, :size, :url, :status_code, :redirected_to
    def initialize(url:)
      @url = url
      @mime_type = ''
      @size = 0
      @status_code = nil
      @timed_out = nil
      @redirected = nil
      @redirected_to = nil
    end

    # this method does the magic and checks the URL
    def validate
      unless correctly_formatted_url?
        @status_code = 400 # bad request because the URL is malformed
        return false
      end

      client = setup_httpclient
      @tries = 3
      begin
        @tries -= 1
        response = client.head(@url, follow_redirect: true)

        @status_code = response.status_code
        @mime_type = response.header['Content-Type'].first unless response.header['Content-Type'].blank?
        @mime_type = @mime_type[/^\S*;/][0..-2] if @mime_type.match(/^\S*;/) # mimetype and not charset stuff after ';'
        @size = response.header['Content-Length'].first.to_i unless response.header['Content-Length'].blank?
        @timed_out = false
        @redirected = !response.previous.nil?
        if @redirected
          @redirected_to = response.previous.header['Location'].first
        end
        return true
          #Socketerror seems to mean a domain that is down or unavailable, tried http://macgyver.com
          # https://carpark.com seems to timeout
          # http://poodle.com -- keep alive disconnected

      rescue SocketError, HTTPClient::KeepAliveDisconnected, HTTPClient::BadResponseError, ArgumentError => ex
        retry if @tries > 0
        @status_code = 499
      rescue HTTPClient::TimeoutError => ex
        @timed_out = true
        @status_code = 408
      end
      false
    end

    def timed_out?
      @timed_out
    end

    def redirected?
      @redirected
    end

    def correctly_formatted_url?
      u = URI.parse(@url)
      u.kind_of?(URI::HTTP)
    end

    private

    def setup_httpclient
      clnt = HTTPClient.new

      # this callback allows following redirects from http to https or opposite, otherwise it will not follow them
      clnt.redirect_uri_callback = ->(uri, res) { res.header['location'][0] }
      clnt.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #clnt.send_timeout = 15
      #clnt.receive_timeout = 15
      clnt
    end

  end
end

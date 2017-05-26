require 'httpclient'

module StashEngine
  class UrlValidator

    attr_reader :mime_type, :size, :url, :status_code, :redirected_to, :filename
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
        # get the filename from either the 1) content disposition, 2) redirected url (if avail) or 3) url
        @filename = filename_from_content_disposition(response.header['Content-Disposition']) ||
                      filename_from_url(@redirected_to) || filename_from_url(@url)
        @filename = last_resort_filename if @filename == '' or @filename == '/'
        return true
          #Socketerror seems to mean a domain that is down or unavailable, tried http://macgyver.com
          # https://carpark.com seems to timeout
          # http://poodle.com -- keep alive disconnected

      rescue SocketError, HTTPClient::KeepAliveDisconnected, HTTPClient::BadResponseError, ArgumentError,
          Errno::ECONNREFUSED => ex
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
    rescue URI::InvalidURIError => ex
      false
    end

    private

    def setup_httpclient
      clnt = HTTPClient.new

      # this callback allows following redirects from http to https or opposite, otherwise it will not follow them
      clnt.redirect_uri_callback = ->(uri, res) { res.header['location'][0] }
      clnt.connect_timeout = 5
      clnt.send_timeout = 5
      clnt.receive_timeout = 5
      clnt.keep_alive_timeout = 5
      clnt.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #clnt.send_timeout = 15
      #clnt.receive_timeout = 15
      clnt
    end

    # the content disposition filename is ugly and there are some variations for ascii vs other encodings such
    # as utf8 and percent encoding of content
    def filename_from_content_disposition(disposition)
      return nil if disposition.blank?
      if match = disposition.match(/filename=([^;$]+)/) #set the match and check for filename, this single equals is on purpose
        # this is a simple case that checks for ascii filenames in content disposition and removes surrounding quotes, if any
        my_match = match[1].strip
        my_match = my_match [1..-2] if my_match[0] == my_match[-1] && "\"'".include?(my_match[0])
        return my_match
      elsif match = disposition.match(/filename\*=\S+'\S*'([^;$]+)/)
        my_match = match[1].strip
        my_match = my_match [1..-2] if my_match[0] == my_match[-1] && "\"'".include?(my_match[0])
        return CGI.unescape(my_match)
      end
      nil
    end

    def filename_from_url(url)
      return nil if url.blank?
      u = URI.parse(url)
      File.basename(u.path)
    end

    # generate a filename as a last resort
    def last_resort_filename
      if correctly_formatted_url?
        URI.parse(@url).host
      else
        nil
      end
    end

  end
end

require 'httpclient'
require 'net/http'
require 'fileutils'
require 'cgi'
require 'byebug'

# getting cert errors, maybe https://www.engineyard.com/blog/ruby-ssl-error-certificate-verify-failed fixes it ?

module StashEngine
  class UrlValidator

    attr_reader :mime_type, :size, :url, :status_code, :redirected_to, :filename

    TIMEOUT = 15

    def initialize(url:)
      @url = url
      @mime_type = 'application/octet-stream'
      @size = 0
      @status_code = nil
      @timed_out = nil
      @redirected = nil
      @redirected_to = nil
    end

    def self.make_unique(resource:, filename:, association:)
      dups = resource.send(association).present_files.where(upload_file_name: filename)
      return filename unless dups.count > 0

      ext = File.extname(filename)
      core_name = File.basename(filename, ext)
      counter = 2
      counter += 1 while resource.send(association).present_files.where(upload_file_name: "#{core_name}-#{counter}#{ext}").count > 0
      "#{core_name}-#{counter}#{ext}"
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
        @timed_out = false
        response = client.head(@url, follow_redirect: true)
        init_from(response)
        # the follow is for google drive which doesn't respond to head requests correctly
        fix_by_get_request(redirected_to || url) if google_drive_redirect?(status_code, redirected_to)
        return true unless @status_code > 399
      rescue HTTPClient::TimeoutError
        @timed_out = true
        @status_code = 408
      rescue SocketError, HTTPClient::KeepAliveDisconnected, HTTPClient::BadResponseError, ArgumentError, Errno::ECONNREFUSED
        # Socketerror seems to mean a domain that is down or unavailable, tried http://macgyver.com
        # https://carpark.com seems to timeout
        # http://poodle.com -- keep alive disconnected
        retry if @tries > 0
        @status_code = 499
      end
      false
    end

    # need to give make_unique method may need moving
    def upload_attributes_from(translator:, resource:, association:)
      valid = validate
      upload_attributes = {
        resource_id: resource.id, url: url,
        status_code: status_code,
        file_state: 'created',
        original_url: (translator.direct_download.nil? ? nil : @url),
        cloud_service: translator.service
      }
      return upload_attributes unless valid && status_code == 200

      # don't allow duplicate URLs that have already been put into this version this time
      # (duplicate indicated with 409 Conflict)
      return upload_attributes.merge(status_code: 409) \
        if resource.url_in_version?(url: url, association: association)

      sanitized_filename = StashEngine::GenericFile
        .sanitize_file_name(UrlValidator
          .make_unique(resource: resource, filename: CGI.unescape(filename), association: association))

      upload_attributes.merge(
        upload_file_name: sanitized_filename,
        original_filename: UrlValidator.make_unique(resource: resource, filename: CGI.unescape(filename), association: association),
        upload_content_type: mime_type,
        upload_file_size: size
      )
    end

    def timed_out?
      @timed_out
    end

    def redirected?
      @redirected
    end

    def correctly_formatted_url?
      u = URI.parse(@url)
      u.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end

    # the content disposition filename is ugly and there are some variations for ascii vs other encodings such
    # as utf8 and percent encoding of content
    def filename_from_content_disposition(disposition)
      disposition = disposition.first if disposition.instance_of?(Array)
      return nil if disposition.blank?

      if (match = disposition.match(/filename=([^;$]+)/)) # simple filenames
        extract_and_unquote(match)
      elsif (match = disposition.match(/filename\*=\S+'\S*'([^;$]+)/)) # rfc5646 shenanigans
        my_match = extract_and_unquote(match)
        CGI.unescape(my_match)
      end
    end

    private

    def setup_httpclient
      clnt = HTTPClient.new

      # this callback allows following redirects from http to https or opposite, otherwise it will not follow them
      clnt.redirect_uri_callback = ->(_uri, res) { res.header['location'][0] }
      clnt.connect_timeout = TIMEOUT
      clnt.send_timeout = TIMEOUT
      clnt.receive_timeout = TIMEOUT
      clnt.keep_alive_timeout = TIMEOUT
      clnt.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      clnt
    end

    def init_from(response)
      @size = size_from(response)
      @status_code = if @size == 0 && response.status_code < 400
                       411 # length required, which we'll require from now on
                     else
                       response.status_code
                     end
      @mime_type = mime_type_from(response)

      # Following is a made-up status code for our own use.  We're not a web crawler and don't accept URLs for HTML pages
      # since we're not going to crawl them and they are usually an error on the user's part or will be missing components
      # such as CSS or images. If they go in then they are probably not doing what the user hopes and they should be warned.
      @status_code = 481 if @mime_type == 'text/html'
      @redirected = !response.previous.nil?
      @redirected_to = response.previous.header['Location'].first if @redirected
      @filename = filename_from(response, @redirected_to, @url)
    end

    def size_from(response)
      content_length = response.header['Content-Length']
      content_length = content_length.first if content_length.instance_of?(Array) && !content_length.blank?
      if content_length.blank?
        0
      else
        content_length.to_i
      end
    end

    def mime_type_from(response)
      content_type = response.header['Content-Type']
      return 'application/octet-stream' if content_type.blank?

      mime_type = (content_type.instance_of?(Array) ? content_type.first : content_type)
      return mime_type unless mime_type =~ /^\S*;/ # mimetype and not charset stuff after ';'

      mime_type[/^\S*;/][0..-2]
    end

    # get the filename from either the 1) content disposition, 2) redirected url (if avail) or 3) url
    def filename_from(response, redirected_to, url)
      filename = filename_from_content_disposition(response.header['Content-Disposition']) ||
        filename_from_url(redirected_to) || filename_from_url(url)
      return filename unless ['', '/'].include?(filename)

      last_resort_filename
    end

    def filename_from_url(url)
      return nil if url.blank?

      u = URI.parse(url)
      File.basename(u.path)
    end

    # generate a filename as a last resort
    def last_resort_filename
      URI.parse(@url).host if correctly_formatted_url?
    end

    def extract_and_unquote(match)
      my_match = match[1].strip
      return my_match unless my_match[0] == my_match[-1] && "\"'".include?(my_match[0])

      my_match[1..-2]
    end

    def fix_by_get_request(u)
      response = get_without_download(URI.parse(u))
      return unless response.code == '200'

      size = size_from(response)
      @status_code = if size == 0 && response.status_code < 400
                       411 # length required
                     else
                       200
                     end
      @mime_type = mime_type_from(response)
      @size = size_from(response)
      @filename = filename_from(response, u, u)
    end

    def get_without_download(url)
      Net::HTTP.start(url.host, url.port, use_ssl: (url.scheme == 'https')) do |conn|
        conn.request_get(url) { |response| return response }
      end
    end

    def google_drive_redirect?(status_code, redirected_to)
      status_code >= 500 && redirected_to.include?('googleusercontent.com')
    end

  end
end

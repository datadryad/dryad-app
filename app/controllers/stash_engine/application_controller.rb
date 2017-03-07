require 'stash/streamer'
require 'httpclient'
require 'uri'

module StashEngine
  class ApplicationController < ::ApplicationController

    include SharedController

    prepend_view_path("#{Rails.application.root}/app/views")

    def force_to_domain
      unless session[:test_domain] || request.host == current_tenant_display.full_domain
        uri = URI(request.original_url)
        uri.host = current_tenant_display.full_domain
        redirect_to(uri.to_s) && return
      end
    end

    def stream_response(url)
      # get original header info from http headers
      clnt = HTTPClient.new
      File.open(File.join(Rails.root, 'tmp', 'cookie.dat'), "w") {} unless File.exists?(File.join(Rails.root, 'tmp', 'cookie.dat'))

      # probably don't need to set the cookie store.
      #clnt.set_cookie_store(File.join(Rails.root, 'tmp', 'cookie.dat'))

      # auth = Base64.strict_encode64("ucop_dash_submitter:a3jg5yAz")
      # clnt.follow_redirect_count = 4

      clnt.set_auth(url, 'ucop_dash_submitter', 'a3jg5yAz')
      # headers = clnt.head(url, {follow_redirect: true}, {'Authorization' => auth})
      headers = clnt.head(url, follow_redirect: true)
      puts headers.http_header['Status']
      puts headers.http_header['Location']
      byebug
      content_type, content_length = '', '0'
      content_type = headers.http_header['Content-Type'].first if headers.http_header['Content-Type'].try(:first)
      content_length = headers.http_header['Content-Length'].first if headers.http_header['Content-Length'].try(:first)

      filename = File.basename(URI.parse(url).path)

      response.headers["Content-Type"] = content_type
      response.headers["Content-Disposition"] = "inline; filename=\"#{filename}\""
      response.headers["Content-Length"] = content_length
      response.headers['Last-Modified'] = Time.now.httpdate
      self.response_body = Stash::Streamer.new(url)
    end

  end
end

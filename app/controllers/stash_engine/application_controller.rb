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

    def stream_response(url, user, pwd)
      # get original header info from http headers
      clnt = HTTPClient.new

      # auth = Base64.strict_encode64("<user>:<pwd>")
      # headers = clnt.head(url, {follow_redirect: true}, {'Authorization' => auth})

      clnt.set_auth(url, user, pwd)

      headers = clnt.head(url, follow_redirect: true)

      content_type = headers.http_header['Content-Type'].try(:first)
      content_length = headers.http_header['Content-Length'].try(:first)
      content_disposition = headers.http_header['Content-Disposition'].try(:first)

      filename = File.basename(URI.parse(url).path)

      response.headers["Content-Type"] = content_type if content_type
      # response.headers["Content-Disposition"] = "inline; filename=\"#{filename}.zip\""
      response.headers["Content-Disposition"] = content_disposition || "inline; filename=\"#{filename}.zip\""
      response.headers["Content-Length"] = content_length || ''
      response.headers['Last-Modified'] = Time.now.httpdate
      self.response_body = Stash::Streamer.new(clnt, url)
    end

  end
end

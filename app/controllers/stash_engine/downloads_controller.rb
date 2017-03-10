require_dependency 'stash_engine/application_controller'
require 'rest-client'

# TODO: how downloads are handled depend heavily on the repository in use, needs moving elsewhere to be flexible
module StashEngine
  class DownloadsController < ApplicationController

    def download_resource
      @resource = Resource.find(params[:resource_id])
      async_download = false
      if @resource.under_embargo?
        # if you're the owner do streaming download
        if current_user && current_user.id == @resource.user_id
          if async_download
            # redirect somewhere for more forms
          else
            stream_response(@resource.merritt_producer_download_uri,
              @resource.tenant.repository.username,
              @resource.tenant.repository.password)
          end
        end
      else
        # not under embargo and public
        # redirect to the producer file download link
        if async_download
          # redirect somewhere to capture email and send different request
        else
          redirect_to @resource.merritt_producer_download_uri
        end
      end
    end

    def async_request
      @resource = Resource.find(params[:resource_id])
      @email = params[:email]
      # this posts the data imitating the large version download form that Merritt uses
      post_async_form(resource: @resource, email: @email)
    end

    private

    # TODO: specific to Merritt and hacky
    # post an async form, right now @resource and @email should be set correctly before calling
    def post_async_form(resource:, email:)
      # set up all needed parameters
      domain, local_id = resource.merritt_domain_and_local_id
      username = resource.tenant.repository.username
      password = resource.tenant.repository.password
      url = "http://#{domain}/lostorage"

      clnt = HTTPClient.new
      # ran into problems like https://github.com/nahi/httpclient/issues/181 so forcing basic auth
      clnt.force_basic_auth = true
      clnt.set_basic_auth(nil, username, password)

      body = { 'object'             =>  local_id,
               'version'            =>  resource.stash_version.version,
               'user_agent_email'   =>  email,
               'uDownload'          =>  'true',
               'commit'             =>  'Submit'}

      # from actual merritt form these are the items being submitted:
      # utf8=%E2%9C%93
      # &authenticity_token=9RYZsKa%2F2bZU7Wp52lotk7Oh6CZMGBUx4EjO0IGbIQk%3D
      # &user_agent_email=scott.fisher%40ucop.edu
      # &uDownload=true
      # &object=ark%253A%252Fb5072%252Ffk2pv6hw34
      # &version=
      # &commit=Submit

      res = clnt.post(url, body, follow_redirect: true)
      # this is sketchy validation, but their form would redirect to that location if it's successful
      unless res.http_header['Location'] && res.http_header['Location'].first.include?("#{domain}/m/#{local_id}")
        raise "Invalid response from Merritt"
      end
    end

    # to stream the response through this UI instead of redirecting, keep login and other stuff private
    def stream_response(url, user, pwd)
      # get original header info from http headers
      clnt = HTTPClient.new

      # auth = Base64.strict_encode64("<user>:<pwd>")
      # headers = clnt.head(url, {follow_redirect: true}, {'Authorization' => auth})

      clnt.force_basic_auth = true
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

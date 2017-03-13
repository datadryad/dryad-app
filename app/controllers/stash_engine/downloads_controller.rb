require_dependency 'stash_engine/application_controller'
require 'rest-client'

# TODO: how downloads are handled depend heavily on the repository in use, needs moving elsewhere to be flexible
module StashEngine
  class DownloadsController < ApplicationController

    def download_resource
      @resource = Resource.find(params[:resource_id])
      if @resource.under_embargo?
        # if you're the owner do streaming download
        if current_user && current_user.id == @resource.user_id
          if merritt_async_download?(resource: @resource)
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
        if merritt_async_download?(resource: @resource)
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
      api_async_download(resource: @resource, email: @email)
    end

    # method to download by the secret sharing link, must match the string they generated to look up and download
    def share
      @shares = Share.where(secret_id: params[:id])
      raise ActionController::RoutingError, 'Not Found' if @shares.count < 1 || @shares.first.expiration_date < Time.new

      @resource = @shares.first.resource

      if merritt_async_download?(resource: @resource)
        #redirect to the form for filling in their email address to get an email
        #don't forget to be sure that action has good security, so that people can't just go
        #to that page and bypass embargoes without a login or a token for downloading
      else
        stream_response(@resource.merritt_producer_download_uri,
                        @resource.tenant.repository.username,
                        @resource.tenant.repository.password)
      end
    end

    private

    # TODO: specific to Merritt and hacky
    # post an async form, right now @resource and @email should be set correctly before calling
    # ---
    # note, it seems as though this has been deprecated and Mark has created an API call for it now
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

    def merritt_async_download?(resource:)
      domain, local_id = resource.merritt_domain_and_local_id
      username = resource.tenant.repository.username
      password = resource.tenant.repository.password
      url = "http://#{domain}/async/#{local_id}/#{resource.stash_version.version}"

      res = http_client_w_basic_auth(username: username, password: password).get(url, nil, follow_redirect: true)
      if res.status_code == 406
        return false  #406 is synchronous
      elsif res.status_code == 200
        return true #200 is code for asyncronous
      else
        raise "unknown status code while determining if async download from Merritt"
      end
    end

    def api_async_download(resource:, email:)
      # set up all needed parameters
      domain, local_id = resource.merritt_domain_and_local_id
      username = resource.tenant.repository.username
      password = resource.tenant.repository.password
      url = "http://#{domain}/asyncd/#{local_id}/#{resource.stash_version.version}"
      params = { user_agent_email: email, userFriendly: true}

      res = http_client_w_basic_auth(username: username, password: password).get(url, params, follow_redirect: true)

      unless res.status_code == 200
        raise "There was a problem making an async download request to Merritt"
      end
    end

    # encapsulates all the settings to make basic auth with a get request work correctly for Merritt
    def http_client_w_basic_auth(username:, password:)
      clnt = HTTPClient.new
      # ran into problems like https://github.com/nahi/httpclient/issues/181 so forcing basic auth
      clnt.force_basic_auth = true
      clnt.set_basic_auth(nil, username, password)
      clnt
    end

    # to stream the response through this UI instead of redirecting, keep login and other stuff private
    def stream_response(url, user, pwd)
      # get original header info from http headers
      clnt = http_client_w_basic_auth(username: user, password: pwd)

      headers = clnt.head(url, nil, follow_redirect: true)

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

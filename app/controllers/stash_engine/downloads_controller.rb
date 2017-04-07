require_dependency 'stash_engine/application_controller'
require 'rest-client'

# TODO: how downloads are handled depend heavily on the repository in use, needs moving elsewhere to be flexible
module StashEngine

  class MerrittResponseError < StandardError; end

  class DownloadsController < ApplicationController

    def download_resource
      @resource = Resource.find(params[:resource_id])

      if @resource.under_embargo?
        # if you're the owner do streaming download
        if current_user && current_user.id == @resource.user_id
          setup_async_download_variable #which may redirect to different page in certain circumstances
          if @async_download
            redirect_to landing_show_path(
                      id: "#{@resource.identifier.identifier_type.downcase}:#{@resource.identifier.identifier}",
                      big: 'showme')
          else
            stream_response(@resource.merritt_producer_download_uri,
              @resource.tenant.repository.username,
              @resource.tenant.repository.password)
          end
        else # no user is logged in for this embargoed item
          flash[:alert] = "This dataset is embargoed and may not be downloaded."
          redirect_to landing_show_path(
                          id: "#{@resource.identifier.identifier_type.downcase}:#{@resource.identifier.identifier}") and return
        end
      else
        # not under embargo and public
        # redirect to the producer file download link
        setup_async_download_variable #which may redirect to different page in certain circumstances
        if @async_download
          redirect_to landing_show_path(
                          id: "#{@resource.identifier.identifier_type.downcase}:#{@resource.identifier.identifier}",
                          big: 'showme')
        else
          redirect_to @resource.merritt_producer_download_uri and return
        end
      end
    end

    def async_request
      @resource = Resource.find(params[:resource_id])
      @email = params[:email]
      session[:saved_email] = @email
      respond_to do |format|
        format.js do
          if !@resource.under_embargo? || ( current_user && current_user.id == @resource.user_id) ||
              ( params[:secret_id] == @resource.share.secret_id )
            api_async_download(resource: @resource, email: @email)
            @resource.increment_downloads
            @message = "Dash will send an email with a download link to #{@email} when your requested dataset is ready."
          else
            @message = 'You do not have the permission to download the dataset.'
          end
        end
      end
    end

    # method to download by the secret sharing link, must match the string they generated to look up and download
    def share
      @shares = Share.where(secret_id: params[:id])
      raise ActionController::RoutingError, 'Not Found' if @shares.count < 1

      @resource = @shares.first.resource
      if @resource.under_embargo?
        setup_async_download_variable #which may redirect to different page in certain circumstances

        if @async_download
          #redirect to the form for filling in their email address to get an email
          redirect_to landing_show_path(
                          id: "#{@resource.identifier.identifier_type.downcase}:#{@resource.identifier.identifier}",
                          big: 'showme', secret_id: params[:id])
        else
          @resource.increment_downloads
          stream_response(@resource.merritt_producer_download_uri,
                          @resource.tenant.repository.username,
                          @resource.tenant.repository.password)
        end
      else
        redirect_to landing_show_path(
          id: "#{@resource.identifier.identifier_type.downcase}:#{@resource.identifier.identifier}"),
          notice: 'The dataset is now published, please use the download button on the right side.'
      end
    end

    private

    # this sets up the async download variable which it determines from Merritt and handles any exceptions with
    # possible redirect to tell people to wait for submission to complete
    def setup_async_download_variable
      @async_download = nil
      begin
        @async_download = merritt_async_download?(resource: @resource)
      rescue StashEngine::MerrittResponseError => ex
        # do something with this exception ex and redirect if it's a recent submission
        if @resource.updated_at > Time.new - 2.hours
          #recently updated, so display a "hold your horses" message
          flash[:notice] = "This dataset was recently submitted and downloads are not yet available. " +
              "Downloads generally become available in less than 2 hours."
          redirect_to landing_show_path(
                          id: "#{@resource.identifier.identifier_type.downcase}:#{@resource.identifier.identifier}")
        else
          raise ex
        end
      end
    end

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
               'version'            =>  resource.stash_version.merritt_version,
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
      url = "http://#{domain}/async/#{local_id}/#{resource.stash_version.merritt_version}"

      res = http_client_w_basic_auth(username: username, password: password).get(url, nil, follow_redirect: true)

      if res.status_code == 406
        return false  #406 is synchronous
      elsif res.status_code == 200
        return true #200 is code for asyncronous
      else
        raise StashEngine::MerrittResponseError,
              "undefined api status code #{res.status_code} obtained while determining if #{url} was an async download from Merritt"
      end
    end

    def api_async_download(resource:, email:)
      # set up all needed parameters
      domain, local_id = resource.merritt_domain_and_local_id
      username = resource.tenant.repository.username
      password = resource.tenant.repository.password
      url = "http://#{domain}/asyncd/#{local_id}/#{resource.stash_version.merritt_version}"
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

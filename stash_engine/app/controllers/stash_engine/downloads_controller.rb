require_dependency 'stash_engine/application_controller'
require 'rest-client'

# TODO: how downloads are handled depend heavily on the repository in use, needs moving elsewhere to be flexible
module StashEngine

  class MerrittResponseError < StandardError
  end

  class DownloadsController < ApplicationController # rubocop:disable Metrics/ClassLength

    def download_resource
      @resource = Resource.find(params[:resource_id])
      if @resource.public?
        download_public
      elsif owner?
        download_as_owner
      else
        unavailable_for_download
      end
    rescue StashEngine::MerrittResponseError => e
      # if it's a recent submission, suggest they try again later; otherwise fail
      raise e unless @resource.updated_at > Time.new - 2.hours

      if Rails.env.development?
        msg = "MerrittResponseError checking sync/async download for resource #{@resource.id} updated at #{@resource.updated_at}"
        backtrace = e.respond_to?(:backtrace) && e.backtrace ? e.backtrace.join("\n") : ''
        logger.warn("#{msg}: #{e.class}: #{e}\n#{backtrace}")
      end

      # recently updated, so display a "hold your horses" message
      flash_download_unavailable
    end

    def async_request # rubocop:disable Metrics/MethodLength
      @resource = Resource.find(params[:resource_id])
      @email = params[:email]
      session[:saved_email] = @email
      respond_to do |format|
        format.js do
          if can_download?
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
      if @resource.private?
        download_embargoed
      else
        redirect_to_public
      end
    end

    private

    def download_public
      setup_async_download_variable
      if @async_download
        redirect_to landing_show_path(id: @resource.identifier_str, big: 'showme')
      else
        redirect_to(@resource.merritt_producer_download_uri)
      end
    end

    def download_as_owner
      setup_async_download_variable
      if @async_download
        redirect_to landing_show_path(id: @resource.identifier_str, big: 'showme')
      else
        stream_response(@resource.merritt_producer_download_uri, @resource.tenant)
      end
    end

    def unavailable_for_download
      flash[:alert] = 'This dataset is private and may not be downloaded.'
      redirect_to(landing_show_path(id: @resource.identifier_str))
    end

    def can_download?
      @resource.public? || owner? || (params[:secret_id] == @resource.share.secret_id)
    end

    def owner?
      current_user && current_user.id == @resource.user_id
    end

    def download_embargoed
      setup_async_download_variable
      if @async_download
        # redirect to the form for filling in their email address to get an email
        show_email_form
      else
        stream_download
      end
    end

    def redirect_to_public
      redirect_to(
        landing_show_path(id: @resource.identifier_str),
        notice: 'The dataset is now published, please use the download button on the right side.'
      )
    end

    def stream_download
      @resource.increment_downloads
      stream_response(@resource.merritt_producer_download_uri, @resource.tenant)
    end

    def show_email_form
      redirect_to landing_show_path(id: @resource.identifier_str, big: 'showme', secret_id: params[:id])
    end

    # this sets up the async download variable which it determines from Merritt
    def setup_async_download_variable
      @async_download = merritt_async_download?(resource: @resource)
    end

    def flash_download_unavailable
      flash[:notice] = [
        'This dataset was recently submitted and downloads are not yet available.',
        'Downloads generally become available in less than 2 hours.'
      ].join(' ')
      redirect_to landing_show_path(id: @resource.identifier_str)
    end

    # TODO: specific to Merritt and hacky
    # post an async form, right now @resource and @email should be set correctly before calling
    # ---
    # note, it seems as though this has been deprecated and Mark has created an API call for it now
    def post_async_form(resource:, email:) # rubocop:disable Metrics/MethodLength
      # set up all needed parameters
      domain, local_id = resource.merritt_protodomain_and_local_id
      url = "#{domain}/lostorage"

      body = {  'object' => local_id,
                'version' => resource.stash_version.merritt_version,
                'user_agent_email' => email,
                'uDownload' => 'true',
                'commit' => 'Submit' }

      # from actual merritt form these are the items being submitted:
      # utf8=%E2%9C%93
      # &authenticity_token=9RYZsKa%2F2bZU7Wp52lotk7Oh6CZMGBUx4EjO0IGbIQk%3D
      # &user_agent_email=scott.fisher%40ucop.edu
      # &uDownload=true
      # &object=ark%253A%252Fb5072%252Ffk2pv6hw34
      # &version=
      # &commit=Submit

      client = http_client_w_basic_auth(resource.tenant)
      res = client.post(url, body, follow_redirect: true)

      # this is sketchy validation, but their form would redirect to that location if it's successful
      location = res.http_header['Location']
      return if location && location.first.include?("#{domain}/m/#{local_id}")

      raise 'Invalid response from Merritt'
    end

    def merritt_async_download?(resource:)
      domain, local_id = resource.merritt_protodomain_and_local_id
      url = "#{domain}/async/#{local_id}/#{resource.stash_version.merritt_version}"

      res = http_client_w_basic_auth(resource.tenant).get(url, follow_redirect: true)
      status = res.status_code

      return true if status == 200 # async download OK
      return false if status == 406 # 406 Not Acceptable means only synchronous download allowed

      raise StashEngine::MerrittResponseError, "Unknown status code #{status} checking for async download #{url}"
    end

    def api_async_download(resource:, email:)
      domain, local_id = resource.merritt_protodomain_and_local_id

      tenant = resource.tenant
      url = "#{domain}/asyncd/#{local_id}/#{resource.stash_version.merritt_version}"
      params = { user_agent_email: email, userFriendly: true }

      res = http_client_w_basic_auth(tenant).get(url, query: params, follow_redirect: true)
      return if res.status_code == 200

      raise 'There was a problem making an async download request to Merritt'
    end

    # encapsulates all the settings to make basic auth with a get request work correctly for Merritt
    def http_client_w_basic_auth(tenant) # rubocop:disable Metrics/AbcSize
      client = HTTPClient.new

      # this callback allows following redirects from http to https, otherwise it will not
      client.redirect_uri_callback = ->(_uri, res) {
        res.header['location'][0]
      }

      # ran into problems like https://github.com/nahi/httpclient/issues/181 so forcing basic auth
      client.force_basic_auth = true
      client.set_basic_auth(nil, tenant.repository.username, tenant.repository.password)
      # TODO: remove this once Merritt has fixed their certs on their stage server.
      client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env == 'stage'
      client.ssl_config.set_trust_ca(APP_CONFIG.ssl_cert_file) if APP_CONFIG.ssl_cert_file
      client
    end

    # to stream the response through this UI instead of redirecting, keep login and other stuff private
    def stream_response(url, tenant) # rubocop:disable Metrics/AbcSize
      # get original header info from http headers
      client = http_client_w_basic_auth(tenant)

      headers = client.head(url, follow_redirect: true)

      content_type = headers.http_header['Content-Type'].try(:first)
      content_length = headers.http_header['Content-Length'].try(:first) || ''
      content_disposition = headers.http_header['Content-Disposition'].try(:first) || disposition_from(url)
      response.headers['Content-Type'] = content_type if content_type
      response.headers['Content-Disposition'] = content_disposition
      response.headers['Content-Length'] = content_length
      response.headers['Last-Modified'] = Time.now.httpdate
      self.response_body = Stash::Streamer.new(client, url)
    end

    def disposition_from(url)
      "inline; filename=\"#{File.basename(URI.parse(url).path)}.zip\""
    end

  end
end

require_dependency 'stash_engine/application_controller'
require 'stash/download/file'
require 'stash/download/version'
# require 'rest-client'


module StashEngine

  class MerrittResponseError < StandardError
  end

  class DownloadsController < ApplicationController # rubocop:disable Metrics/ClassLength

    before_action :setup_streaming

    # set up the Merritt file & version objects so they have access to the controller context for returning responses, setting headers, etc
    def setup_streaming
      @version_streamer = Stash::Download::Version.new(controller_context: self)
      @file_streamer = Stash::Download::File.new(controller_context: self)
    end

    # for downloading the full version
    # rubocop:disable Metrics/MethodLength
    def download_resource
      @resource = Resource.find(params[:resource_id])
      if @resource.may_download?(user: current_user)
        download_full_version{ redirect_to landing_show_path(id: @resource.identifier_str, big: 'showme') }
      else
        unavailable_for_download
      end
    rescue StashEngine::MerrittResponseError => e
      # if it's a recent submission, suggest they try again later; otherwise fail
      raise e unless @resource.updated_at > Time.new - 2.hours
      log_warning_if_needed(e)
      # recently updated, so display a "hold your horses" message
      flash_download_unavailable
    end
    # rubocop:enable Metrics/MethodLength

    # handles a large dataset that may only be downloaded asynchronously from Merritt because of size limits for immediate downloads
    # rubocop:disable Metrics/MethodLength
    def async_request
      @resource = Resource.find(params[:resource_id])
      @email = params[:email]
      session[:saved_email] = @email
      respond_to do |format|
        format.js do
          if can_download? # local method that checks if user may download or if their secret matches
            api_async_download(resource: @resource, email: @email)
            @message = "Dash will send an email with a download link to #{@email} when your requested dataset is ready."
            CounterLogger.version_download_hit(request: request, resource: @resource)
          else
            @message = 'You do not have the permission to download the dataset.'
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # method to download by the secret sharing link, must match the string they generated to look up and download
    def share
      @shares = Share.where(secret_id: params[:id])
      raise ActionController::RoutingError, 'Not Found' if @shares.count < 1

      @resource = @shares.first.resource
      unless @resource.files_public?
        download_full_version { redirect_to private_async_form_path(id: @resource.identifier_str, big: 'showme', secret_id: params[:id]) }
      else
        redirect_to_public
      end
    end

    # shows the form for private async.  Usually part of the landing page for dataset, but page may not exist for public
    # anymore because of curation so we create a new page to host the form
    def private_async_form
      @share = Share.where(secret_id: params[:secret_id])&.first
      @resource = @share.resource
    end

    def file_stream
      if file_upload&.resource&.may_download?(user: current_user)
        CounterLogger.general_hit(request: request, file: file_upload)
        @file_streamer.stream_response(url: file_upload.merritt_url, tenant: current_user.tenant)
      else
        render status: 403, text: 'You are not authorized to download this file until it has been published.'
      end
    end

    private

    def file_upload
      @file_upload ||= FileUpload.find(params[:file_id])
    end

    # this downloads a full version as a stream from Merritt UI and takes a block with a redirect for
    # the place to go for an asynchronous download from Merritt
    def download_full_version
      setup_async_download_variable
      if @async_download
        yield
      else
        CounterLogger.version_download_hit(request: request, resource: @resource)
        @version_streamer.stream_response(url: @resource.merritt_producer_download_uri, tenant: @resource.tenant)
      end
    end

    def unavailable_for_download
      flash[:alert] = 'This dataset is private and may not be downloaded.'
      redirect_to(landing_show_path(id: @resource.identifier_str))
    end

    def can_download?
      @resource.may_download?(user: current_user) || (params[:secret_id] == @resource.share.secret_id)
    end

    def redirect_to_public
      redirect_to(
        landing_show_path(id: @resource.identifier_str),
        notice: 'This dataset is now published, please use the download button on the right side.'
      )
    end

    def stream_download
      CounterLogger.version_download_hit(request: request, resource: @resource)
      Stash::Download::Version.stream_response(url: @resource.merritt_producer_download_uri, tenant: @resource.tenant)
    end

    # this sets up the async download variable which it determines from Merritt
    def setup_async_download_variable
      @async_download = @version_streamer.merritt_async_download?(resource: @resource)
    end

    def flash_download_unavailable
      flash[:notice] = [
        'This dataset was recently submitted and downloads are not yet available.',
        'Downloads generally become available in less than 2 hours.'
      ].join(' ')
      redirect_to landing_show_path(id: @resource.identifier_str)
    end

    # TODO: Move into separate class, all stuff below this (I think)

    # rubocop:disable Metrics/MethodLength
    def api_async_download(resource:, email:)
      url = merritt_friendly_async_url(resource: resource)

      email_from = [APP_CONFIG['contact_email']].flatten.first
      email_subject = "Your download for #{resource.title} is ready"
      email_body = File.read(File.join(StashEngine::Engine.root, 'app', 'views', 'stash_engine', 'downloads', 'async_email.txt.erb'))

      params = { user_agent_email: email, userFriendly: true, losFrom: email_from, losSubject: email_subject, losBody: email_body }

      res = Stash::Repo::HttpClient.new(tenant: resource.tenant, cert_file: APP_CONFIG.ssl_cert_file)
        .client.get(url, query: params, follow_redirect: true)
      status = res.status_code
      return if status == 200

      query_string = HTTP::Message.create_query_part_str(params)
      raise_merritt_error('Merritt async download request', "unexpected status #{status}", resource.id, "#{url}?#{query_string}")
    end
    # rubocop:enable Metrics/MethodLength

    # TODO: move this into a merritt-specific module
    def merritt_friendly_async_url(resource:)
      domain, local_id = resource.merritt_protodomain_and_local_id
      "#{domain}/asyncd/#{local_id}/#{resource.stash_version.merritt_version}"
    end

    def log_warning_if_needed(e)
      return unless Rails.env.development?
      msg = "MerrittResponseError checking sync/async download for resource #{@resource.id} updated at #{@resource.updated_at}"
      backtrace = e.respond_to?(:backtrace) && e.backtrace ? e.backtrace.join("\n") : ''
      logger.warn("#{msg}: #{e.class}: #{e}\n#{backtrace}")
    end

    def disposition_from(url)
      "inline; filename=\"#{File.basename(URI.parse(url).path)}.zip\""
    end

    def raise_merritt_error(operation, details, resource_id, uri)
      raise StashEngine::MerrittResponseError, "#{operation}: #{details} for resource ID #{resource_id}, URL #{uri}"
    end
  end
end

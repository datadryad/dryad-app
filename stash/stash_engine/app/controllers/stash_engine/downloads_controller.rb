require_dependency 'stash_engine/application_controller'
require 'stash/download/file_presigned'
require 'stash/download/version'

# rubocop:disable Metrics/ClassLength
module StashEngine
  class DownloadsController < ApplicationController

    CONCURRENT_DOWNLOAD_LIMIT = 2

    before_action :check_user_agent, :check_ip, :stop_download_hogs, :setup_streaming

    def check_user_agent
      # This reads a text file with one line and a regular expression in it and blocks if the user-agent matches the regexp
      agent_path = Rails.root.join('uploads', 'blacklist_agents.txt').to_s
      head(429) if File.exist?(agent_path) && request.user_agent[Regexp.new(File.read(agent_path))]
    end

    def check_ip
      # This looks for uploads/blacklist.txt and if it's there matches IP addresses that start with things in the file--
      # one IP address (or beginning of IP Address) per line.
      block_path = Rails.root.join('uploads', 'blacklist.txt').to_s
      return unless File.exist?(block_path)

      File.read(block_path).split("\n").each do |exc|
        next if exc.blank? || exc.start_with?('#')

        if request&.remote_ip&.start_with?(exc)
          head(429)
          break
        end
      end
    end

    def stop_download_hogs
      dl_count = DownloadHistory.where(ip_address: request&.remote_ip).downloading.count
      render 'download_limit', status: 429 if dl_count >= CONCURRENT_DOWNLOAD_LIMIT
    end

    # set up the Merritt file & version objects so they have access to the controller context before continuing
    def setup_streaming
      @version_streamer = Stash::Download::Version.new(controller_context: self)
      @file_presigned = Stash::Download::FilePresigned.new(controller_context: self)
    end

    # for downloading the full version
    def download_resource
      @resource = Resource.find(params[:resource_id])
      if @resource.may_download?(ui_user: current_user)
        @version_streamer.download(resource: @resource) do
          redirect_to landing_show_path(id: @resource.identifier_str, big: 'showme') # if it's an async
        end
      else
        unavailable_for_download
      end
    rescue Stash::Download::MerrittResponseError => e
      # if it's a recent submission, suggest they try again later; otherwise fail
      raise e unless @resource.updated_at > Time.new.utc - 2.hours
      Stash::Download::Base.log_warning_if_needed(error: e, resource: @resource)
      # recently updated, so display a "hold your horses" message
      flash_download_unavailable
    end

    # handles a large dataset that may only be downloaded asynchronously from Merritt because of size limits for immediate downloads
    def async_request
      @resource = Resource.find(params[:resource_id])
      @email = params[:email]
      session[:saved_email] = @email
      respond_to do |format|
        format.js do
          if can_download? # local method that checks if user may download or if their secret matches
            api_async_download(resource: @resource, email: @email)
            @message = "Dryad will send an email with a download link to #{@email} when your requested dataset is ready."
            CounterLogger.version_download_hit(request: request, resource: @resource)
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

      @resource = @shares.first.identifier&.last_submitted_resource
      if !@resource.files_published?
        @version_streamer.download(resource: @resource) do
          redirect_to private_async_form_path(id: @resource.identifier_str, big: 'showme', secret_id: params[:id]) # for async
          return
        end
      else
        redirect_to_public
      end
    end

    # shows the form for private async.  Usually part of the landing page for dataset, but page may not exist for public
    # anymore because of curation so we create a new page to host the form
    def private_async_form
      @share = Share.where(secret_id: params[:secret_id])&.first
      @resource = @share.identifier&.last_submitted_resource
    end

    def file_stream
      file_upload = FileUpload.find(params[:file_id])
      if file_upload&.resource&.may_download?(ui_user: current_user)
        CounterLogger.general_hit(request: request, file: file_upload)
        @file_presigned.download(file: file_upload)
      else
        render status: 403, text: 'You are not authorized to download this file until it has been published.'
      end
    end

    private

    def unavailable_for_download
      flash[:alert] = 'This dataset is private and may not be downloaded.'
      redirect_to(landing_show_path(id: @resource.identifier_str))
    end

    def can_download?
      @resource.may_download?(ui_user: current_user) ||
          (!params[:secret_id].blank? && @resource&.identifier&.shares&.where(secret_id: params[:secret_id])&.count&.positive?)
    end

    def redirect_to_public
      redirect_to(
        landing_show_path(id: @resource.identifier_str),
        notice: 'This dataset is now published, please use the download button on the right side.'
      )
    end

    def flash_download_unavailable
      flash[:notice] = [
        'This dataset was recently submitted and downloads are not yet available.',
        'Downloads generally become available in less than 2 hours.'
      ].join(' ')
      redirect_to landing_show_path(id: @resource.identifier_str)
    end

    def api_async_download(resource:, email:)
      url = Stash::Download::Version.merritt_friendly_async_url(resource: resource)

      email_from = [APP_CONFIG['contact_email']].flatten.first
      email_subject = "Your download for #{resource.title} is ready"
      email_body = File.read(File.join(StashEngine::Engine.root, 'app', 'views', 'stash_engine', 'downloads', 'async_email.txt.erb'))

      params = { user_agent_email: email, userFriendly: true, losFrom: email_from, losSubject: email_subject, losBody: email_body }

      res = Stash::Repo::HttpClient.new(tenant: resource.tenant, cert_file: APP_CONFIG.ssl_cert_file)
        .client.get(url, query: params, follow_redirect: true)
      status = res.status_code
      return if status == 200

      query_string = HTTP::Message.create_query_part_str(params)
      Stash::Download::Version.raise_merritt_error('Merritt async download request',
                                                   "unexpected status #{status}", resource.id, "#{url}?#{query_string}")
    end

  end
end
# rubocop:enable Metrics/ClassLength

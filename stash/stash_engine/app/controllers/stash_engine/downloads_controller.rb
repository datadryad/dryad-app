require_dependency 'stash_engine/application_controller'
require 'stash/download/file_presigned'
require 'stash/download/version_presigned'

# rubocop:disable Metrics/ClassLength
module StashEngine
  class DownloadsController < ApplicationController
    include ActionView::Helpers::DateHelper

    CONCURRENT_DOWNLOAD_LIMIT = 2

    before_action :check_user_agent, :check_ip, :setup_streaming
    # :stop_download_hogs,

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
      @file_presigned = Stash::Download::FilePresigned.new(controller_context: self)
    end

    # for downloading the full version
    def download_resource
      @resource = nil
      @resource = Resource.where(id: params[:resource_id]).first if params[:share].nil?
      check_for_sharing

      @version_presigned = Stash::Download::VersionPresigned.new(resource: @resource)
      unless @version_presigned.valid_resource? && ( @resource.may_download?(ui_user: current_user) || @sharing_link )
        render status: 404, text: "404: Not found or invalid download\n"
        return
      end

      respond_to do |format|
        format.html do
          @status_hash = @version_presigned.download
          if @status_hash[:status] == 200
            redirect_to status_hash[:url]
          elsif @status_hash[:status] == 202
            render status: 202, text: "The version of the dataset is being assembled. " \
              "Check back in around #{time_ago_in_words(@resource.download_token.available + 30.seconds)} and it should be ready to download."
          else
            render status: 404, text: 'Not found'
          end
        end
        format.js do
          @status_hash = @version_presigned.download
        end
      end
    end

    # checks assembly status for a resource and returns json from Merritt and http-ish status code, from progressbar polling
    def assembly_status
      @resource = nil
      @resource = Resource.where(id: params[:id]).first if params[:share].nil?
      check_for_sharing

      @version_presigned = Stash::Download::VersionPresigned.new(resource: @resource)
      unless @version_presigned.valid_resource? && ( @resource.may_download?(ui_user: current_user) || @sharing_link )
        render json: {status: 202} # it will never be ready for them
        return
      end

      @status_hash = @version_presigned.status
      render json: @status_hash
    end

    # method to download by the secret sharing link, must match the string they generated to look up and download
    def share
      @resource = resource_from_share
      raise ActionController::RoutingError, 'Not Found' if @resource.blank?

      if @resource.files_published?
        redirect_to_public
      end
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

    def resource_from_share
      my_id = params[:share] || params[:id]
      return nil if my_id.blank?

      @share = Share.where(secret_id: my_id).first
      return nil if @share.blank?

      @share&.identifier&.last_submitted_resource
    end

    def check_for_sharing
      @sharing_link = false

      if @resource.blank? && params[:share]
        @resource = resource_from_share
        @sharing_link = true if @resource
      end
    end

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

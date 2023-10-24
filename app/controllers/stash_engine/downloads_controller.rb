require 'stash/download/file_presigned'
require 'stash/download/version_presigned'
require 'http'

module StashEngine
  class DownloadsController < ApplicationController
    include ActionView::Helpers::DateHelper

    before_action :check_user_agent, :check_ip, :setup_streaming

    def check_user_agent
      # This reads a text file with one line and a regular expression in it and blocks if the user-agent matches the regexp
      agent_path = Rails.root.join('uploads', 'blacklist_agents.txt').to_s
      return if request.user_agent.blank?

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
      unless @version_presigned.valid_resource? && (@resource.may_download?(ui_user: current_user) || @sharing_link)
        render status: 404, plain: "404: Not found or invalid download\n"
        return
      end

      respond_to do |format|
        format.html do
          non_ajax_response_for_download
        end
        format.js do
          @status_hash = @version_presigned.download
          log_counter_version if @status_hash[:status] == 200
          if @status_hash[:status] == 408
            notify_download_timeout
            render 'download_timeout'
            return
          end
        end
      end
    end

    # checks assembly status for a resource and returns json from Merritt and http-ish status code, from progressbar polling
    def assembly_status
      @resource = nil
      @resource = Resource.where(id: params[:id]).first if params[:share].nil?
      check_for_sharing

      @version_presigned = Stash::Download::VersionPresigned.new(resource: @resource)
      unless @version_presigned.valid_resource? && (@resource.may_download?(ui_user: current_user) || @sharing_link)
        render json: { status: 202 } # it will never be ready for them, this url isn't useful except to legit users so shouldn't happen
        return
      end

      @status_hash = @version_presigned.status
      log_counter_version if @status_hash[:status] == 200 # because this triggers the download when it has this status
      logger.warn("Timeout in downloads_controller#assembly_status for #{@resource&.id}") if @status_hash[:status] == 408
      render json: @status_hash
    rescue HTTP::TimeoutError
      logger.warn("HTTP Timeout from Merritt in downloads_controller#assembly_status for Resource #{@resource&.id}")
      render json: { status: 408 }
    end

    # method to download by the secret sharing link, must match the string they generated to look up and download
    def share
      @resource = resource_from_share
      raise ActionController::RoutingError, 'Not Found' if @resource.blank?

      redirect_to(app_404_path) if @resource.identifier.pub_state == 'withdrawn'
      redirect_to_public if @resource.files_published?
    end

    # uses presigned
    def file_stream
      data_file = DataFile.find(params[:file_id])
      if data_file&.resource&.may_download?(ui_user: current_user)
        CounterLogger.general_hit(request: request, file: data_file)
        @file_presigned.download(file: data_file)
      else
        render status: 403, plain: 'You are not authorized to download this file until it has been published.'
      end
    end

    # Downloads a zenodo file, by Resource Access Tokens presigned, maybe will need to do both RATs and public download.
    # Also may need to enable passing secret token for sharing access and right now we only supply Zenodo downloads for
    # private access, not to the general public which should go to Zenodo to examine the full info and downloads.
    def zenodo_file
      zen_upload = GenericFile.where(id: params[:file_id]).first
      res = zen_upload&.resource
      share = (params[:share].blank? ? nil : StashEngine::Share.where(secret_id: params[:share]).first)

      # can see if they had permission or the Share matches the identifier
      if res && (res&.may_download?(ui_user: current_user) || share&.identifier_id == res&.identifier&.id)
        if res.zenodo_published?
          redirect_to zen_upload.public_zenodo_download_url
        else
          zen_presign = zen_upload.zenodo_presigned_url
          if zen_presign.nil?
            render plain: 'Unable to get a presigned URL for this file.', status: 500
            return
          end

          redirect_to zen_presign
        end
      else
        render status: 403, plain: 'You are not authorized to download this file'
      end
    end

    def preview_csv
      @data_file = DataFile.find(params[:file_id])
      @preview = (@data_file.preview_file if @data_file&.resource&.may_download?(ui_user: current_user))

      # limit to only 5 lines at most and make unix line endings
      return unless @preview.instance_of?(String)

      @preview = @preview.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') # replace bad chars
      @preview = @preview.split(/[\r\n|]+/).map(&:strip)[0..5].join("\n") # only 5 lines, please
    end

    private

    def non_ajax_response_for_download
      @status_hash = @version_presigned.download
      case @status_hash[:status]
      when 200
        log_counter_version
        redirect_to @status_hash[:url]
      when 202
        render status: 202,
               plain: 'The version of the dataset is being assembled. ' \
                      "Check back in around #{time_ago_in_words(@resource.download_token.available + 30.seconds)} and it should be ready to download."
      when 408
        notify_download_timeout
        render status: 408, plain: 'The dataset assembly service is currently unresponsive. Try again later or download each individual file.'
      else
        render status: 404, plain: 'Not found'
      end
    end

    def resource_from_share
      my_id = params[:share] || params[:id]
      return nil if my_id.blank?

      @share = Share.where(secret_id: my_id).first
      return nil if @share.blank?

      @share&.identifier&.last_submitted_resource
    end

    def check_for_sharing
      @sharing_link = false

      return unless @resource.blank? && params[:share]

      @resource = resource_from_share
      @sharing_link = true if @resource
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

    def log_counter_version
      CounterLogger.version_download_hit(request: request, resource: @resource)
    end

    def notify_download_timeout
      msg = "Timeout in downloads_controller#download_resource for resource #{@resource&.id} for IP #{request.remote_ip}"
      logger.warn(msg)
      ExceptionNotifier.notify_exception(Stash::Download::MerrittException.new(msg))
    end

  end
end

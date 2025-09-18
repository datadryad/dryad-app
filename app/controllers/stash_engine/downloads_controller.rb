require 'stash/download/file_presigned'
require 'http'

module StashEngine
  # rubocop:disable Metrics/ClassLength
  class DownloadsController < ApplicationController
    include ActionView::Helpers::DateHelper
    include StashEngine::LandingHelper

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

    # set up the file & version objects so they have access to the controller context before continuing
    def setup_streaming
      @file_presigned = Stash::Download::FilePresigned.new(controller_context: self)
    end

    def zip_assembly_info
      # input is resource_id and output is json with keys size, filename and url for each entry
      @resource = Resource.where(id: params[:resource_id]).first
      @resource = nil if params[:share]
      check_for_sharing
      return render json: ['unauthorized'], status: :unauthorized unless @resource&.may_download?(ui_user: current_user) || @sharing_link

      respond_to do |format|
        format.json do
          # input is resource_id and output is json with keys size, filename and url for each entry
          @resource = Resource.find(params[:resource_id])

          info = @resource.data_files.present_files.map do |f|
            {
              size: f.upload_file_size,
              filename: f.download_filename,
              url: f.s3_permanent_presigned_url
            }
          end
          render json: info
        end
      end
    end

    # for downloading the full version
    # uses presigned
    def download_resource
      @resource = Resource.where(id: params[:resource_id]).first
      @resource = nil if params[:share]
      check_for_sharing

      @version_presigned = Stash::Download::VersionPresigned.new(controller_context: self, resource: @resource)
      if @version_presigned.valid_resource? && (@resource&.may_download?(ui_user: @user) || @sharing_link)
        @version_presigned.download(resource: @resource)
      else
        render plain: 'Download for this dataset is unavailable', status: 404
      end
    end

    # method to download by the secret sharing link, must match the string they generated to look up and download
    def share
      @resource = resource_from_share
      raise ActionController::RoutingError, 'Not Found' if @resource.blank?

      redirect_to(app_404_path) if @resource.identifier.pub_state == 'withdrawn'
      redirect_to_public and return if @resource.files_published? &&
      (@resource.identifier.has_accepted_manuscript? || @resource.identifier.publication_article_doi.present?)
    end

    # uses presigned
    def file_stream
      check_for_sharing
      data_file = DataFile.where(id: params[:file_id]).present_files.first
      if data_file&.resource&.may_download?(ui_user: current_user) || @sharing_link
        response.set_header(
          'Link',
          "<#{file_linkset_url(id: data_file.id)}>; rel=\"linkset\"; type=\"application/linkset\",
          <#{file_linkset_url(id: data_file.id)}.json>; rel=\"linkset\"; type=\"application/linkset+json\",
          <#{show_url(id: data_file.resource.identifier_str)}> ; rel=\"collection\" ; type=\"text/html\""
        )
        @file_presigned.download(file: data_file)
      else
        render status: 403, plain: 'You may not download this file.'
      end
    end

    # uses presigned
    def presubmit_file_stream
      file = GenericFile.where(id: params[:file_id]).present_files.first
      if file&.resource&.may_view?(ui_user: current_user)
        @file_presigned.in_submission_download(file: file)
      else
        render status: 403, plain: 'You may not download this file.'
      end
    end

    def linkset
      @file = DataFile.where(id: params[:file_id]).present_files.first
      respond_to do |format|
        format.html do
          response.set_header('Content-Type', 'application/linkset')
          render body: lset_linkset
        end
        format.json do
          response.set_header('Content-Type', 'application/linkset+json')
          render json: json_linkset
        end
      end
    end

    # Downloads a zenodo file, by Resource Access Tokens presigned, maybe will need to do both RATs and public download.
    # Also may need to enable passing secret token for sharing access and right now we only supply Zenodo downloads for
    # private access, not to the general public which should go to Zenodo to examine the full info and downloads.
    def zenodo_file
      zen_upload = GenericFile.where(id: params[:file_id]).first # gets cast to the specific type
      res = zen_upload&.resource
      share = (params[:share].blank? ? nil : StashEngine::Share.where(secret_id: params[:share]).first)

      # can see if they had permission or the Share matches the identifier
      if res && (res&.may_download?(ui_user: current_user) || share&.identifier_id == res&.identifier&.id) &&
          [StashEngine::SuppFile, StashEngine::SoftwareFile].include?(zen_upload.class)
        if res.zenodo_published?
          redirect_to zen_upload.public_zenodo_download_url, allow_other_host: true
        else
          zen_presign = zen_upload.zenodo_presigned_url
          if zen_presign.nil?
            render plain: 'Unable to get a presigned URL for this file.', status: 500
            return
          end

          redirect_to zen_presign, allow_other_host: true
        end
      else
        render status: 403, plain: 'You are not authorized to download this file'
      end
    end

    def preview_check
      @file = DataFile.find(params[:file_id])
    end

    def preview_file
      @file = DataFile.find(params[:file_id])

      if %w[csv txt].include?(@file.preview_type)
        @preview = @file.text_preview
        @sep = SniffColSeparator.find(@file.sniff_file) if @file_type == 'csv'
      else
        @preview = @file.preview_type.present?
      end
    end

    private

    def lset_linkset
      "<#{show_url(id: @file.resource.identifier_str)}>; rel=\"collection\" type=\"text/html\" anchor=\"#{download_stream_url(file_id: @file.id)}\",
      <https://schema.org/DataDownload>; rel=\"type\" anchor=\"#{download_stream_url(file_id: @file.id)}\""
    end

    def json_linkset
      {
        linkset: [
          anchor: download_stream_url(file_id: @file.id),
          type: [{ href: 'https://schema.org/DataDownload' }],
          collection: [
            {
              href: show_url(id: @file.resource.identifier_str),
              type: 'text/html'
            }
          ]
        ]
      }
    end

    def non_ajax_response_for_download
      @status_hash = @version_presigned.download
      case @status_hash[:status]
      when 200
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
        notice: "This dataset is published. Please use #{@resource.identifier_uri}."
      )
    end

    def flash_download_unavailable
      flash[:notice] = [
        'This dataset was recently submitted and downloads are not yet available.',
        'Downloads generally become available in less than 2 hours.'
      ].join(' ')
      redirect_to landing_show_path(id: @resource.identifier_str)
    end

    def notify_download_timeout
      msg = "Timeout in downloads_controller#download_resource for resource #{@resource&.id} for IP #{request.remote_ip}"
      logger.warn(msg)
      ExceptionNotifier.notify_exception(Stash::Download::S3CustomError.new(msg))
    end
    # rubocop:enable Metrics/ClassLength
  end
end

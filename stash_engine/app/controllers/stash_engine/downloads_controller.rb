require_dependency 'stash_engine/application_controller'
require 'stash/download/file'
require 'stash/download/version'
require 'tempfile'
require 'down'
require 'down/wget'
# require 'rest-client'
#

class Rack::Response
  def close
    @body.close if @body.respond_to?(:close)
  end
end



# rubocop:disable Metrics/ClassLength
module StashEngine
  class DownloadsController < ApplicationController
    before_action :setup_streaming

    # set up the Merritt file & version objects so they have access to the controller context before continuing
    def setup_streaming
      @version_streamer = Stash::Download::Version.new(controller_context: self)
      @file_streamer = Stash::Download::File.new(controller_context: self)
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
      @resource = @share.resource.identifier&.last_submitted_resource
    end

    def file_stream
      file_upload = FileUpload.find(params[:file_id])
      if file_upload&.resource&.may_download?(ui_user: current_user)
        CounterLogger.general_hit(request: request, file: file_upload)
        @file_streamer.download(file: file_upload)
      else
        render status: 403, text: 'You are not authorized to download this file until it has been published.'
      end
    end
    
    private

    # these are for rack full hijacking


    def send_headers(stream, header_obj)
      headers = [ 'HTTP/1.1 200 OK' ]
      headers_to_keep = ['Content-Type', 'content-type', 'Content-Length', 'content-length', 'ETag']
      heads = header_obj.slice(headers_to_keep)
      heads.merge( 'Content-Disposition'  => 'attachment; funn.file',
                   'X-Accel-Buffering'    => 'no',
                   'Cache-Control'        => 'no-cache',
                   'Last-Modified'        => Time.zone.now.ctime.to_s )
      heads.each_pair { |k,v| headers.push("#{k}: #{v}")  }

      stream.write(headers.map { |header| header + "\r\n" }.join)
      stream.write("\r\n")
      stream.flush
    rescue
      stream.close
      raise
    end

    def perform_task(out_stream, in_stream)
      chunk_size = 1024 * 1024
      begin
        until in_stream.eof?
          out_stream.write(in_stream.read(chunk_size))
        end
      rescue StandardError => ex
        logger.error("while streaming: #{ex}")
        logger.error("while streaming: #{ex.backtrace}")
      ensure
        out_stream.close
        in_stream.close
      end
    end



    # rack hijacking

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

    def stream_download
      CounterLogger.version_download_hit(request: request, resource: @resource)
      Stash::Download::Version.stream_response(url: @resource.merritt_producer_download_uri, tenant: @resource.tenant)
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

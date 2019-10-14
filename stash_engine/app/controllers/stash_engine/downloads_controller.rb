require_dependency 'stash_engine/application_controller'
require 'stash/download/file'
require 'stash/download/version'
require 'tempfile'
require 'down'
# require 'rest-client'

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

    def test_stream
      url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
      response.headers['Content-Type'] = 'image/tiff'
      response.headers['Content-Disposition'] = 'attachment; filename="funn.tif"'
      response.headers["X-Accel-Buffering"] = 'no'
      response.headers["Cache-Control"] = 'no-cache'
      response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

      response.headers["rack.hijack"] = proc do |stream|

        Thread.new do
          begin
            http = HTTP.timeout(connect: 3000, read: 3000, write: 1500).timeout(7200)
            # .basic_auth(user: 'xxx', pass: 'xxx')
            response = http.get(url)
            response.body.each do |chunk|
              stream.write(chunk)
            end
          rescue HTTP::Error => ex
            logger.error("while streaming: #{ex}")
            logger.error("while streaming: #{ex.backtrace}")
          ensure
            stream.close
          end
        end
      end
      head :ok
    end

    def test_stream2
      url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
      response.headers['Content-Type'] = 'image/tiff'
      response.headers['Content-Disposition'] = 'attachment; filename="funn.tif"'
      response.headers["X-Accel-Buffering"] = 'no'
      response.headers["Cache-Control"] = 'no-cache'
      # response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

      response.headers["rack.hijack"] = proc do |stream|

        Thread.new do
          begin
            conn = Faraday.new
            conn.get(url) do |req|
              # Set a callback which will receive tuples of chunk Strings
              # and the sum of characters received so far
              req.options.on_data = Proc.new do |chunk, overall_received_bytes|
                # puts "Received #{overall_received_bytes} characters"
                stream.write(chunk)
              end
            end
          rescue StandardError => ex
            logger.error("while streaming: #{ex}")
            logger.error("while streaming: #{ex.backtrace}")
          ensure
            stream.close
          end
        end
      end
      head :ok
    end

    def test_stream3
      url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
      response.headers['Content-Type'] = 'image/tiff'
      response.headers['Content-Disposition'] = 'attachment; filename="funn.tif"'
      response.headers["X-Accel-Buffering"] = 'no'
      response.headers["Cache-Control"] = 'no-cache'
      response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

      response.headers["rack.hijack"] = proc do |stream|
      # downloaded_file = File.open 'huge.iso', 'wb'
        Thread.new do
          request = Typhoeus::Request.new(url)
          request.on_headers do |response|
            if response.code != 200
              raise "Request failed"
              logger.error ('while streaming: request failed')
            end
          end
          request.on_body do |chunk|
            stream.write(chunk)
          end
          request.on_complete do |response|
            stream.close
            # Note that response.body is ""
          end
          request.run
        end
      end
      head :ok
    end

    def test_stream4
      url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
      response.headers['Content-Type'] = 'image/tiff'
      response.headers['Content-Disposition'] = 'attachment; filename="funn.tif"'
      response.headers['X-Accel-Buffering'] = 'no'
      response.headers['Cache-Control'] = 'no-cache'
      response.headers['Last-Modified'] = Time.zone.now.ctime.to_s

      response.headers["rack.hijack"] = proc do |stream|

        Thread.new do
          streamer = lambda do |chunk, remaining_bytes, total_bytes|
            stream.write(chunk)
            # puts "Remaining: #{remaining_bytes.to_f / total_bytes}%"
          end

          begin
            Excon.get(url, :response_block => streamer)
          rescue Excon::Errors, StandardError => ex
            logger.error("while streaming: #{ex}")
            logger.error("while streaming: #{ex.backtrace}")
          end
        end
      end
      head :ok
    end

    def test_stream5
      url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
      response.headers['Content-Type'] = 'image/tiff'
      response.headers['Content-Disposition'] = 'attachment; filename="funn.tif"'
      response.headers["X-Accel-Buffering"] = 'no'
      response.headers["Cache-Control"] = 'no-cache'
      response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

      response.headers["rack.hijack"] = proc do |stream|

        Thread.new do
          begin
            f = nil
            begin
              # first stream entire file to file system
              # see https://twin.github.io/httprb-is-great/ or https://github.com/httprb/http/wiki
              http = HTTP.timeout(connect: 3600, read: 3600, write: 3600).timeout(3600)
              response = http.get(url)
              logger.info('downloading file in chunks')
              # f = File.open('outfile.tif', 'wb')
              # according to docs create doesn't autodelete tempfile and acts like normal file, we need to ensure deletion
              f = Tempfile.create('dlfile', Rails.root.join('uploads')).binmode
              response.body.each do |chunk|
                f.write(chunk)
              end
            rescue HTTP::Error => ex
              logger.error("while retrieving: #{ex}")
              logger.error("while retrieving: #{ex.backtrace}")
            ensure
              f.close
            end

            begin
              chunk_size = 1024 * 1024
              logger.info('sending file in chunks')
              f2 = File.open(f.path, 'rb')
              until f2.eof?
                stream.write(f2.read(chunk_size))
              end
            rescue StandardError => ex
              logger.error("while sending: #{ex}")
              logger.error("while sending: #{ex.backtrace}")
            ensure
              stream.close
              f2.close
            end
          ensure
            f.unlink
          end
        end
      end
      head :ok
    end

    def test_stream6
      url = 'https://www.spacetelescope.org/static/archives/images/publicationtiff40k/heic1502a.tif'
      response.headers['Content-Type'] = 'image/tiff'
      response.headers['Content-Disposition'] = 'attachment; filename="funn.tif"'
      response.headers["X-Accel-Buffering"] = 'no'
      response.headers["Cache-Control"] = 'no-cache'
      response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

      response.headers["rack.hijack"] = proc do |stream|

        Thread.new do
          chunk_size = 1024 * 1024
          begin
            remote_file = Down.open(url, rewindable: false)
            # .basic_auth(user: 'xxx', pass: 'xxx')
            until remote_file.eof?
              stream.write(remote_file.read(chunk_size))
            end
          rescue StandardError => ex
            logger.error("while streaming: #{ex}")
            logger.error("while streaming: #{ex.backtrace}")
          ensure
            stream.close
          end
        end
      end
      head :ok
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

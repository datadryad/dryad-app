require_dependency 'stash_engine/application_controller'
require 'securerandom'

module StashEngine
  class LandingController < ApplicationController # rubocop:disable Metrics/ClassLength
    # LandingMixin should provide:
    # - has_geolocation?
    # - pdf_meta
    include StashEngine.app.metadata_engine.constantize::LandingMixin

    before_action :require_identifier_and_resource, only: %i[show data_paper]
    protect_from_forgery(except: [:update])

    # ############################################################
    # Helper methods

    def id
      @id ||= identifier_from(params)
    end

    helper_method :id

    # -- gets the resource for display from the identifier --
    # This gets more complicated because we are displaying the latest curation state of
    # 'published' or 'embargoed' if it's to the public.
    #
    # For logged in curators (role: 'superuser'), they get to see the latest version, no matter what state
    # if the param '?show_latest=true' is stuck on the URL.
    #
    # For admins or logged in owners, they get to see the latest version submitted to Merritt
    #
    # For everyone else they just get to see what is accepted by curation
    def resource
      @resource ||=
        if params[:latest] == 'true' && current_user&.superuser? # let superusers see the latest, unpublished if they wish
          id.resources.by_version_desc.first
        # let user see his own if logged in or let superuser see non-latest-preview stuff
        elsif (current_user && (current_user.id == id.resources.submitted.by_version_desc.first.user_id)) || current_user&.superuser?
          id.resources.submitted.by_version_desc.first
        else # everyone else only gets to see published or embargoed metadata latest version
          id.latest_resource_with_public_metadata
        end
    end

    helper_method :resource

    def resource_id
      resource.id
    end

    helper_method :resource_id

    # ############################################################
    # Actions

    def show
      CounterLogger.general_hit(request: request, resource: resource)
      ensure_has_geolocation!
      @invitations = (params[:invitation] ? OrcidInvitation.where(secret: params[:invitation]).where(identifier_id: id.id) : nil)
    end

    def data_paper
      CounterLogger.general_hit(request: request, resource: resource)
      ensure_has_geolocation!

      # lots of problems getting all styles and javascript to load with wicked pdf
      # https://github.com/mileszs/wicked_pdf/issues/257
      # https://github.com/mileszs/wicked_pdf
      show_as_html = params[:debug] ? true : false
      respond_to do |format|
        format.any(:html, :pdf) do
          render_pdf(pdf_meta, show_as_html)
        end
      end
    end

    def citations
      @identifier = Identifier.find(params[:identifier_id])
      respond_to do |format|
        format.js
      end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    # PATCH /dataset/doi:10.xyz/abc
    def update
      return render(nothing: true, status: 404) unless id

      record_identifier = params[:record_identifier]
      return render(nothing: true, status: 400) unless record_identifier

      # get this exact resource by id and version number
      resources = id.resources.joins(:stash_version).where(['stash_engine_versions.version = ? ', params[:stash_version]])

      return render(nothing: true, status: 404) unless resources.count == 1

      # set the @resource variable which is returned by the caching method "resource" if @resource is set
      @resource = resources.first

      my_state = resource.current_resource_state.resource_state
      return render(nothing: true, status: 204) if my_state == 'submitted'  # already switched state, don't do more than once, but give happy response
      return render(nothing: true, status: 400) if my_state != 'processing' # only change processing items to submitted

      # lib/stash/repo/repository calls stash-merritt/lib/stash/merritt/repository.rb and this populates download and update URIs into the db
      StashEngine.repository.harvested(identifier: id, record_identifier: record_identifier)

      # success but no content, see RFC 5789 sec. 2.1
      update_size!
      # now that the OAI-PMH feed has confirmed it's in Merritt then cleanup, but not before
      ::StashEngine.repository.cleanup_files(@resource)
      render(nothing: true, status: 204)
    rescue ArgumentError => e
      logger.debug(e)
      render(nothing: true, status: 422) # 422 Unprocessable Entity, see RFC 5789 sec. 2.2
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity

    # ############################################################
    # Private

    private

    def require_identifier_and_resource
      render('not_available', status: 404) unless id && resource
    end

    def ensure_has_geolocation!
      old_value = resource.has_geolocation
      new_value = geolocation_data?
      return unless old_value != new_value

      resource.has_geolocation = new_value
      resource.save!
    end

    def render_pdf(pdf_meta, show_as_html) # rubocop:disable Metrics/MethodLength
      render(
        pdf: review.pdf_filename,
        page_size: 'Letter',
        title: review.title_str,
        javascript_delay: 3000,
        # 'use_xserver' => true,
        margin: { top: 20, bottom: 20, left: 20, right: 20 },
        header: {
          left: pdf_meta.top_left,
          right: pdf_meta.top_right,
          font_size: 9,
          spacing: 5
        },
        footer: {
          left: pdf_meta.bottom_left,
          right: pdf_meta.bottom_right,
          font_size: 9,
          spacing: 5
        },
        show_as_html: show_as_html
      )
    end

    def identifier_from(params)
      params.require(:id)
      id_param = params[:id].upcase
      type, id = id_param.split(':', 2)
      logger.error("Can't parse identifier from id_param '#{id_param}'") && return unless id

      identifiers = Identifier.where(identifier_type: type).where(identifier: id)
      logger.warn("Identifier '#{id}' not found (id_param was: '#{id_param}')") if identifiers.empty?

      identifiers.first
    end

    # updates the total size & call to update zero sizes for individual files
    def update_size!
      return unless resource
      ds_info = Stash::Repo::DatasetInfo.new(id)
      id.update(storage_size: ds_info.dataset_size)
      update_zero_sizes!(ds_info)
    end

    def update_zero_sizes!(ds_info_obj)
      return unless resource
      resource.file_uploads.where(upload_file_size: 0).where(file_state: 'created').each do |f|
        f.update(upload_file_size: ds_info_obj.file_size(f.upload_file_name))
      end
    end

  end
end

require_dependency 'stash_engine/application_controller'
require 'securerandom'

module StashEngine
  class LandingController < ApplicationController # rubocop:disable Metrics/ClassLength
    # LandingMixin should provide:
    # - has_geolocation?
    # - pdf_meta
    include StashEngine.app.metadata_engine.constantize::LandingMixin

    before_action :require_identifier, except: %i[update citations]
    before_action :require_submitted_resource, except: %i[update citations]
    protect_from_forgery(except: [:update])

    # ############################################################
    # Helper methods

    def id
      @id ||= identifier_from(params)
    end

    helper_method :id

    def resource
      @resource ||= id.last_submitted_resource
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

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    # PATCH /dataset/doi:10.xyz/abc
    def update
      return render(nothing: true, status: 404) unless id

      record_identifier = params[:record_identifier]
      return render(nothing: true, status: 400) unless record_identifier
      resource = id.processing_resource

      StashEngine.repository.harvested(identifier: id, record_identifier: record_identifier)

      # success but no content, see RFC 5789 sec. 2.1
      if resource # does processing stuff only if it is processing now and is thus actually changing state. Don't redo stuff for Harvester re-solring
        deliver_invitations!
        update_size!
      end
      render(nothing: true, status: 204)
    rescue ArgumentError => e
      logger.debug(e)
      render(nothing: true, status: 422) # 422 Unprocessable Entity, see RFC 5789 sec. 2.2
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    # ############################################################
    # Private

    private

    def require_identifier
      render('not_available', status: 404) unless id
    end

    def require_submitted_resource
      render('not_available', status: 404) unless resource
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

    # --- These are for delivering orcid invitations when we get the callback that an item has been processed

    def deliver_invitations! # rubocop:disable Metrics/AbcSize
      return unless resource
      authors = resource.authors.where.not(author_email: nil)
      authors.each do |author|
        next if author.author_email.blank? || StashEngine::OrcidInvitation.where(email: author.author_email)
            .where(identifier_id: id.id).count > 0
        invite = create_invite(author)
        StashEngine::UserMailer.orcid_invitation(invite).deliver_now
      end
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

    def create_invite(author)
      StashEngine::OrcidInvitation.create(
        email: author.author_email,
        identifier_id: id.id,
        first_name: author.author_first_name,
        last_name: author.author_last_name,
        secret: SecureRandom.urlsafe_base64,
        invited_at: Time.new
      )
    end
  end
end

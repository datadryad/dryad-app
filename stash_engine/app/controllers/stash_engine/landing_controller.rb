require_dependency 'stash_engine/application_controller'

module StashEngine
  class LandingController < ApplicationController
    # LandingMixin should provide:
    # - has_geolocation?
    # - pdf_meta
    include StashEngine.app.metadata_engine.constantize::LandingMixin

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

    def show
      unless id && resource
        render 'not_available'
        return
      end
      resource.increment_views
      ensure_has_geolocation!
    end

    def data_paper
      render 'not_available' && return unless id
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

    protect_from_forgery(except: [:update])
    # PATCH /dataset/doi:10.xyz/abc
    def update # rubocop:disable Metrics/MethodLength
      params.require(:record_identifier)

      identifier = identifier_from(params)
      render(nothing: true, status: 404) && return unless identifier

      repo = StashEngine.repository
      begin
        repo.harvested(identifier: identifier, record_identifier: params[:record_identifier])
        # success but no content, see RFC 5789 sec. 2.1
        render(nothing: true, status: 204)
      rescue ArgumentError => e
        logger.debug(e)
        render(nothing: true, status: 422) # 422 Unprocessable Entity, see RFC 5789 sec. 2.2
      end
    end

    private

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
  end
end

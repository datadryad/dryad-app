require 'securerandom'

module StashEngine
  class LandingController < ApplicationController
    # LandingMixin should provide:
    # - has_geolocation?
    include StashDatacite::LandingMixin

    before_action :require_identifier_and_resource, only: %i[show]
    protect_from_forgery(except: [:update])

    # apply Pundit?

    # ############################################################
    # Helper methods

    def id
      @id ||= identifier_from(params)
    end

    helper_method :id

    # -- gets the resource for display from the identifier --
    # some users get to see more than the public such as owners, curators, admins
    def resource
      return @resource unless @resource.nil?

      @user_type = 'public'
      res = id.resources.submitted&.by_version_desc&.first
      return res if res.nil? # no submitted resources

      @resource = if admin?(resource: res)
                    @user_type = 'privileged'
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
      CounterLogger.general_hit(request: request, resource: resource) if resource.metadata_published?
      ensure_has_geolocation!
      @invitations = (params[:invitation] ? OrcidInvitation.where(secret: params[:invitation]).where(identifier_id: id.id) : nil)
      respond_to(&:html)
    end

    def citations
      @identifier = Identifier.find(params[:identifier_id])
      respond_to(&:js)
    end

    def metrics
      @identifier = Identifier.find(params[:identifier_id])
      respond_to(&:js)
    end

    # ############################################################
    # Private

    private

    def require_identifier_and_resource
      # at least one of these will be nil when it doesn't exist or the user doesn't have permission
      render('not_available', status: 404) unless id && resource
    end

    def ensure_has_geolocation!
      old_value = resource.has_geolocation
      new_value = geolocation_data?
      return unless old_value != new_value

      resource.has_geolocation = new_value
      resource.save!
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

require 'securerandom'

module StashEngine
  class LandingController < ApplicationController
    # LandingMixin should provide:
    # - has_geolocation?
    include StashDatacite::LandingMixin

    before_action :require_identifier_and_resource, only: %i[show]
    protect_from_forgery(except: [:update])

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
      respond_to do |format|
        format.html
      end
    end

    def citations
      @identifier = Identifier.find(params[:identifier_id])
      respond_to do |format|
        format.js
      end
    end

    def metrics
      @identifier = Identifier.find(params[:identifier_id])
      respond_to do |format|
        format.js
      end
    end

    # PATCH /dataset/doi:10.xyz/abc
    def update
      return render(body: nil, status: 404) unless id

      record_identifier = params[:record_identifier]
      return render(body: nil, status: 400) unless record_identifier

      # get this exact resource by id and version number
      resources = id.resources.joins(:stash_version).where(['stash_engine_versions.version = ? ', params[:stash_version]])

      return render(body: nil, status: 404) unless resources.count == 1

      # set the @resource variable which is returned by the caching method "resource" if @resource is set
      @resource = resources.first

      my_state = resource.current_resource_state.resource_state
      return render(body: nil, status: 204) if my_state == 'submitted'  # already switched state, don't do more than once, but give happy response
      return render(body: nil, status: 400) if my_state != 'processing' # only change processing items to submitted

      # lib/stash/repo/repository calls stash-merritt/lib/stash/merritt/repository.rb and this populates download and update URIs into the db
      StashEngine.repository.harvested(identifier: id, record_identifier: record_identifier)

      if StashEngine::RepoQueueState.where(resource_id: @resource_id, state: 'completed').count < 1
        StashEngine.repository.class.update_repo_queue_state(resource_id: @resource.id, state: 'completed')
      end

      # success but no content, see RFC 5789 sec. 2.1
      update_size!
      # now that the OAI-PMH feed has confirmed it's in Merritt then cleanup, but not before
      ::StashEngine.repository.cleanup_files(@resource)
      render(body: nil, status: 204)
    rescue ArgumentError => e
      logger.debug(e)
      render(body: nil, status: 422) # 422 Unprocessable Entity, see RFC 5789 sec. 2.2
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

    # updates the total size & call to update zero sizes for individual files
    def update_size!
      return unless resource

      ds_info = Stash::Repo::DatasetInfo.new(id)
      id.update(storage_size: ds_info.dataset_size)
      update_zero_sizes!(ds_info)
    end

    def update_zero_sizes!(ds_info_obj)
      return unless resource

      resource.data_files.where(upload_file_size: 0).where(file_state: 'created').each do |f|
        f.update(upload_file_size: ds_info_obj.file_size(f.upload_file_name))
      end
    end

  end
end

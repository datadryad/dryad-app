require_dependency 'stash_engine/application_controller'

module StashEngine
  class MetadataEntryPagesController < ApplicationController
    before_action :require_login
    before_action :resource_exist, except: [:metadata_callback]
    before_action :require_resource_owner, except: [:metadata_callback]

    # GET/POST/PUT  /generals/find_or_create
    def find_or_create
      @resource = Resource.find(params[:resource_id])
      return unless @resource.published?
      redirect_to(metadata_entry_pages_new_version_path(resource_id: params[:resource_id]))
    end

    # create a new version of this resource before editing with find or create
    def new_version
      # create new version deep copy of most items
      @resource = Resource.find(params[:resource_id])
      identifier = @resource.identifier
      in_progress_version = identifier && identifier.in_progress_version
      if in_progress_version
        redirect_to(metadata_entry_pages_find_or_create_path(resource_id: in_progress_version.id)) && return
      end
      @new_res = @resource.amoeba_dup
      @new_res.save!

      # redirect to find or create path
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: @new_res.id)
    end

    def metadata_callback # rubocop:disable Metrics/AbcSize
      auth_hash = request.env['omniauth.auth']
      params = request.env['omniauth.params']
      StashEngine::Author.create(
        resource_id: params['resource_id'],
        author_first_name: auth_hash.info.first_name,
        author_last_name: auth_hash.info.last_name,
        author_orcid: auth_hash.uid
      )
      redirect_to request.env['omniauth.origin']
    end

    private

    def resource_exist
      @resource = Resource.find(params[:resource_id])
      redirect_to root_path, notice: 'The dataset you are looking for does not exist.' if @resource.nil?
    end

    def require_resource_owner
      return if current_user.id == @resource.user_id
      flash[:alert] = 'You do not have permission to modify this dataset.'
      redirect_to stash_engine.dashboard_path
    end
  end
end

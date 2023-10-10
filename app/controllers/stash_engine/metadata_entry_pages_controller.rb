module StashEngine
  class MetadataEntryPagesController < ApplicationController
    before_action :require_login, except: %i[edit_by_doi]
    before_action :resource_exist, except: %i[metadata_callback]
    before_action :require_modify_permission, except: %i[metadata_callback edit_by_doi]
    before_action :require_in_progress_editor, only: %i[find_or_create]
    before_action :require_can_duplicate, only: %i[new_version new_version_from_previous]
    before_action :ajax_require_modifiable, only: %i[reject_agreement accept_agreement]
    before_action :bust_cache, only: %i[find_or_create]
    before_action :require_not_obsolete, only: %i[find_or_create]

    # apply Pundit?

    def resource
      @resource ||= Resource.find(params[:resource_id])
    end
    helper_method :resource

    # def cedar_popup
    #  print("CEDAR popup: params are #{params}")
    #  respond_to(&:js)
    # end

    # GET/POST/PUT  /generals/find_or_create
    def find_or_create
      @resource&.purge_duplicate_subjects!

      return unless @resource.submitted? # create a new version if this is a submitted version

      redirect_to(stash_url_helpers.metadata_entry_pages_new_version_path(resource_id: params[:resource_id]))
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # GET /stash/edit/{doi}/{edit_code}
    def edit_by_doi
      if resource.processing?
        redirect_to stash_url_helpers.root_path, alert: 'The target dataset is being processed. Please try again later.' and return
      end

      # if this call was made with a returnURL, save it that URL in the session for the end of the submission process
      session[:returnURL] = params[:returnURL] if params[:returnURL]

      # check if edit_code is present, and if so, store in the session
      valid_edit_code?

      if ownership_transfer_needed?
        if current_user
          ca = CurationActivity.create(status: @resource.current_curation_status || 'in_progress',
                                       user_id: 0,
                                       resource_id: @resource.id,
                                       note: "Transferring ownership to #{current_user.name} (#{current_user.id}) using an edit code")
          @resource.curation_activities << ca
          @resource.user_id = current_user.id
          @resource.current_editor_id = current_user.id
          @resource.save
        else
          # The user will need to login (possibly creating an
          # account), and then they will be redirected back to this
          # method to receive ownership of the dataset
          flash[:alert] = 'You must be logged in.'
          session[:target_page] = request.fullpath
          redirect_to stash_url_helpers.choose_login_path and return
        end
      end

      # If the user is logged in, they will remain logged in, just with the added benefit
      # that they have access to edit this dataset. But if they were not logged in,
      # log them in as the dataset owner, and ensure the tenant_id is set correctly.
      unless current_user
        session[:user_id] = resource.user_id
        if current_user.tenant_id.blank?
          session[:target_page] = stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: resource.id)
          redirect_to stash_url_helpers.choose_sso_path and return
        end
      end

      if @resource&.current_resource_state&.resource_state == 'in_progress'
        redirect_to(stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: resource.id))
      else
        new_version
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # create a new version of this resource before editing with find or create
    def new_version
      # save a URL to go back to if possible, for each individual identifier since may have many windows open
      session["return_url_#{@identifier.id}"] = params[:return_url] if params[:return_url] && @identifier
      duplicate_resource

      # redirect to find or create path
      redirect_to stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: @new_res.id)
    end

    def new_version_from_previous
      session["return_url_#{@identifier.id}"] = params[:return_url] if params[:return_url] && @identifier
      prev_resource = @identifier.latest_resource # reference for undoing versioning and files from the duplication, if needed
      prev_files = prev_resource.generic_files
      duplicate_resource

      # now fix the files based on last resource rather than the duplicated one, since we're not copying old files to S3
      # from all the different services (Merritt, Zenodo) which could be error-prone and take some time
      @new_res.generic_files.destroy_all
      prev_files.each do |f|
        next if f.deleted? # deleted so no longer exists here

        # create new based on file record from immediately previous version before the version being created
        my_hash = f.as_json
        my_hash.delete('id')
        my_hash['file_state'] = 'copied'
        my_hash['resource_id'] = @new_res.id
        my_hash['type'] = f.type # otherwise this doesn't get set in the as_json hash
        @new_res.generic_files.create(my_hash)
      end

      redirect_to stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: @new_res.id)
    end

    def reject_agreement
      respond_to do |format|
        format.js do
          resource.destroy if resource.title.nil? && resource.descriptions.first.description.nil?
        end
      end
    end

    def accept_agreement
      respond_to do |format|
        format.json do
          resource.update(accepted_agreement: true)
          render json: resource
        end
      end
    end

    private

    def ownership_transfer_needed?
      valid_edit_code? && (resource.user_id == 0)
    end

    def resource_exist
      resource = Resource.find(params[:resource_id]) if params[:resource_id]
      resource = resource_from_doi if resource.nil?
      redirect_to stash_url_helpers.root_path, alert: 'The dataset you are looking for does not exist.' if resource.nil?
    end

    def resource_from_doi
      doi = params[:doi]
      doi&.match(/doi:(.*)/) do |m|
        doi = m[1]
      end
      id = Identifier.where(identifier: doi).first
      @resource = id&.latest_resource
      params[:resource_id] = @resource&.id
      @resource
    end

    def duplicate_resource
      @new_res = @resource.amoeba_dup
      @new_res.current_editor_id = current_user&.id
      # The default curation activity gets set to the `Resource.user_id` but we want to use the current user here
      @new_res.curation_activities.update_all(user_id: current_user&.id)
      @new_res.save!
    end

    def require_can_duplicate
      return false unless (@identifier = resource.identifier)

      set_return_to_path_from_referrer # needed for dropping into edit (and back) from various places in the ui

      if @identifier.in_progress_only?
        @identifier.in_progress_resource.update(current_editor_id: current_user&.id)
        redirect_to(stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: @identifier.in_progress_resource.id))
        false
      elsif @identifier.processing? || @identifier.error?
        redirect_to stash_url_helpers.dashboard_path,
                    alert: 'You may not create a new version of the dataset until processing completes or any errors are resolved'
        false
      end
    end

  end
end

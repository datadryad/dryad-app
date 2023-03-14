module StashEngine
  class ResourcesController < ApplicationController

    before_action :require_login
    before_action :require_modify_permission, except: %i[index new]
    before_action :require_in_progress, only: %i[upload review upload_manifest up_code up_code_manifest]
    # before_action :lockout_incompatible_uploads, only: %i[upload upload_manifest]
    before_action :lockout_incompatible_sfw_uploads, only: %i[up_code up_code_manifest]
    before_action :update_internal_search, only: %i[upload review upload_manifest up_code up_code_manifest]
    before_action :bust_cache, only: %i[upload manifest up_code up_code_manifest review]
    before_action :require_not_obsolete, only: %i[upload manifest up_code up_code_manifest review]

    attr_writer :resource

    def resource
      @resource ||= (resource_id = params[:id]) && Resource.find(resource_id)
    end
    helper_method :resource

    # GET /resources
    # GET /resources.json
    def index
      @resources = Resource.where(user_id: current_user.id)
    end

    # GET /resources/1
    # GET /resources/1.json
    def show
      respond_to do |format|
        format.xml { render template: '/stash_datacite/resources/show' }
        format.json
      end
    end

    # the show_files is for refreshing the files lists to their default states for the resource
    def show_files
      @uploads = resource.latest_file_states
      respond_to(&:js)
    end

    # GET /resources/new
    def new
      create
    end

    # GET /resources/1/edit
    def edit; end

    # POST /resources
    # POST /resources.json
    def create
      resource = Resource.new(user_id: current_user.id, current_editor_id: current_user.id, tenant_id: current_user.tenant_id)
      my_id = Stash::Doi::IdGen.mint_id(resource: resource)
      id_type, id_text = my_id.split(':', 2)
      db_id_obj = Identifier.create(identifier: id_text, identifier_type: id_type.upcase)
      resource.identifier_id = db_id_obj.id
      resource.save
      resource.fill_blank_author!
      import_manuscript_using_params(resource) if params['journalID']
      redirect_to stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: resource.id)
      # TODO: stop this bad practice of catching a way overly broad error it needs to be specific
    rescue StandardError => e
      logger.error("Unable to create new resource: #{e.full_message}")
      redirect_to stash_url_helpers.dashboard_path, alert: 'Unable to register a DOI at this time. Please contact help@datadryad.org for assistance.'
    end

    # PATCH/PUT /resources/1
    # PATCH/PUT /resources/1.json
    def update
      respond_to do |format|
        if resource.update(resource_params)
          format.html { redirect_to edit_resource_path(resource), notice: 'Resource was successfully updated.' }
          format.json { render :edit, status: :ok, location: resource }
        else
          format.html { render :edit }
          format.json { render json: resource.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /resources/1
    # DELETE /resources/1.json
    def destroy
      resource.destroy
      respond_to do |format|
        format.html do
          # There is a return URL for a simple case and backwards compatibility (only for for whole user and for journals).
          # There is also one for curators and need to return back to different pages/filter setting for each dataset they
          # edit in one of dozens of different windows at the same time, so needs to be specific to each dataset.
          notice = 'The in-progress version was successfully deleted.'
          if session["return_url_#{@resource.identifier_id}"] || session[:returnURL]
            return_url = session["return_url_#{@resource.identifier_id}"] || session[:returnURL]
            session["return_url_#{@resource.identifier_id}"] = nil
            session[:returnURL] = nil
            redirect_to return_url, notice: notice
          elsif current_user
            redirect_to return_to_path_or(dashboard_path), notice: notice
          else
            redirect_to root_path, notice: notice
          end
        end
        format.json { head :no_content }
      end
    end

    # Review responds as a get request to review the resource before saving
    def review
      # record a payment exemption if there is one, before submission
      @resource&.identifier&.record_payment
    end

    # Submission of the resource to the repository
    def submission; end

    # Upload files view for resource
    def upload
      @file_model = StashEngine::DataFile
      @resource_assoc = :data_files

      @file = DataFile.new(resource_id: resource.id) # this seems needed for the upload control
      @uploads = resource.latest_file_states
      # render 'upload_manifest' if resource.upload_type == :manifest
    end

    # upload by manifest view for resource
    def upload_manifest
      @file_model = StashEngine::DataFile
      @resource_assoc = :data_files
    end

    # Upload files view for resource
    def up_code
      @file_model = StashEngine::SoftwareFile
      @resource_assoc = :software_files

      @file = SoftwareFile.new(resource_id: resource.id) # this seems needed for the upload control
      @uploads = resource.latest_file_states(model: 'StashEngine::SoftwareFile')
      if resource.upload_type(association: 'software_files') == :manifest
        render 'upload_manifest'
      else
        render 'upload'
      end
    end

    # upload by manifest view for resource
    def up_code_manifest
      @file_model = StashEngine::SoftwareFile
      @resource_assoc = :software_files
      render 'upload_manifest'
    end

    # patch request
    # Saves the setting of the import type (manuscript, published, other).  While this is set on the identifier, put it
    # here because we already have the resource controller, including permission checking and no identifier controller.
    def import_type
      respond_to do |format|
        format.json do
          @resource.identifier.update(import_info: params[:import_info])
          render json: { import_info: params[:import_info] }, status: :ok
        end
      end
    end

    private

    # We have parameters requesting to match to a Manuscript object; prefill journal info and import metadata if possible
    def import_manuscript_using_params(resource)
      return unless resource && params['journalID'] && params['manu']

      j = StashEngine::Journal.where(journal_code: params['journalID'].downcase).first
      return unless j

      ident = resource.identifier.id

      # Save the journal and manuscript information in the dataset
      StashEngine::InternalDatum.create(data_type: 'publicationISSN', value: j.single_issn, identifier_id: ident)
      StashEngine::InternalDatum.create(data_type: 'publicationName', value: j.title, identifier_id: ident)
      StashEngine::InternalDatum.create(data_type: 'manuscriptNumber', value: params['manu'], identifier_id: ident)

      # If possible, import existing metadata from the Manuscript objects into the dataset
      manu = StashEngine::Manuscript.where(journal: j, manuscript_number: params['manu']).first
      return unless manu

      dryad_import = Stash::Import::DryadManuscript.new(resource: resource, manuscript: manu)
      dryad_import.populate
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.require(:resource).permit(:user_id, :current_resource_state_id)
    end

    def require_in_progress
      redirect_to dashboard_path, alert: 'You may only edit the current version of the dataset' unless resource.current_state == 'in_progress'
      false
    end

    def lockout_incompatible_uploads
      if request[:action] == 'upload' && resource.upload_type == :manifest
        redirect_to upload_manifest_resource_path(resource)
      elsif request[:action] == 'upload_manifest' && resource.upload_type == :files
        redirect_to upload_resource_path(resource)
      end
    end

    def lockout_incompatible_sfw_uploads
      if request[:action] == 'up_code' && resource.upload_type(association: 'software_files') == :manifest
        redirect_to up_code_manifest_resource_path(resource)
      elsif request[:action] == 'up_code_manifest' && resource.upload_type(association: 'software_files') == :files
        redirect_to up_code_resource_path(resource)
      end
    end

    # this is to be sure that our internal search index gets updated occasionally before full submission so search is better
    def update_internal_search
      @resource&.identifier&.update_search_words!
    end

  end
end

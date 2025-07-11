# rubocop:disable Metrics/ClassLength
module StashEngine
  class ResourcesController < ApplicationController
    include StashEngine::LandingHelper

    before_action :require_login
    before_action :assign_resource, only: %i[logout display_readme dupe_check]
    before_action :require_modify_permission, except: %i[index new logout display_readme dupe_check]
    before_action :require_in_progress, only: %i[upload review upload_manifest up_code up_code_manifest]
    # before_action :lockout_incompatible_uploads, only: %i[upload upload_manifest]
    before_action :lockout_incompatible_sfw_uploads, only: %i[up_code up_code_manifest]
    before_action :update_internal_search, only: %i[upload review upload_manifest up_code up_code_manifest]
    before_action :bust_cache, only: %i[upload manifest up_code up_code_manifest review]
    before_action :require_not_obsolete, only: %i[upload manifest up_code up_code_manifest review]
    # after_action :verify_authorized, only: %i[create]

    # apply Pundit?

    attr_writer :resource

    def resource
      @resource ||= (resource_id = params[:id]) && Resource.find(resource_id)
    end
    helper_method :resource

    # GET /resources
    # GET /resources.json
    def index
      @resources = policy_scope(Resource)
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

    # POST /resources
    # POST /resources.json
    def create
      resource = authorize Resource.new(current_editor_id: current_user.id, tenant_id: current_user.tenant_id)
      my_id = Stash::Doi::DataciteGen.mint_id(resource: resource)
      id_type, id_text = my_id.split(':', 2)
      db_id_obj = Identifier.create(identifier: id_text, identifier_type: id_type.upcase)
      resource.update(identifier_id: db_id_obj.id)
      resource.creator = current_user.id
      resource.submitter = current_user.id
      resource.fill_blank_author!
      import_manuscript_using_params(resource) if params['journalID']
      session[:resource_type] = current_user.min_app_admin? && params.key?(:collection) ? 'collection' : 'dataset'
      redirect_to stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: resource.id)
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
      StashEngine::DeleteDatasetsService.new(resource, current_user: current_user).call

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
            redirect_to(return_url, allow_other_host: true, notice: notice)
          elsif current_user
            redirect_to return_to_path_or(choose_dashboard_path), notice: notice
          else
            redirect_to root_path, notice: notice
          end
        end
        format.json { head :no_content }
      end
    end

    def logout
      @resource.update_columns(current_editor_id: nil)
      respond_to do |format|
        format.html { redirect_to dashboard_path }
        format.js { render js: "document.getElementById('editor_name#{@resource.id}').innerHTML='<em>None</em>';" }
      end
    end

    # rubocop:disable Metrics/AbcSize
    def prepare_readme
      @file_list = @resource.data_files.present_files.reject { |f| f.download_filename == 'README.md' }.map do |f|
        h = { name: f.download_filename }
        if f.download_filename.end_with?('.csv', '.tsv', '.xlsx', '.xls', '.rdata', '.rda', '.mat', '.txt')
          h[:variables] = []
          if f.previewable? && (sep = SniffColSeparator.find(f.sniff_file))
            h[:variables] = f.sniff_file.lines.first.chomp.split(sep).map { |c| c.delete_prefix('"').delete_suffix('"') }
          end
        end
        h
      end
      if @resource.descriptions.type_technical_info.try(:description) && !@resource.descriptions.type_technical_info.try(:description).empty?
        @file_content = nil
      else
        readme_file = @resource&.data_files&.present_files&.where(download_filename: 'README.md')&.first
        # Load correctly encoded README.md for editing and otherwise display an error.
        if readme_file&.file_content
          content_string = readme_file.file_content
          encoding = content_string.encoding
          if encoding == Encoding::ASCII_8BIT
            content_string = content_string.force_encoding(encoding).encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '')
          end
          @loading_error = true if content_string.encoding != Encoding::UTF_8
          @file_content = content_string.encoding == Encoding::UTF_8 ? content_string : nil
        else
          @file_content = nil
        end
      end
      render json: { readme_file: @file_content, file_list: @file_list }
    end

    def display_readme
      review = StashDatacite::Resource::Review.new(@resource)
      render partial: 'stash_datacite/descriptions/readme', locals: { review: review }
    end

    def dpc_status
      @resource.check_add_readme_file
      @resource.check_add_cedar_json
      dpc_checks = {
        total_file_size: @resource.total_file_size,
        journal_will_pay: @resource.identifier.journal&.will_pay?,
        institution_will_pay: @resource.identifier.institution_will_pay?,
        funder_will_pay: @resource.identifier.funder_will_pay?,
        user_must_pay: @resource.identifier.user_must_pay?,
        paying_funder: @resource.identifier.funder_payment_info&.contributor_name,
        aff_tenant: StashEngine::Tenant.find_by_ror_id(@resource.identifier&.submitter_affiliation&.ror_id)&.partner_list&.first,
        allow_review: @resource.identifier.allow_review?,
        automatic_ppr: @resource.identifier.automatic_ppr?,
        man_decision_made: @resource.identifier.has_accepted_manuscript? || @resource.identifier.has_rejected_manuscript?
      }
      render json: dpc_checks
    end

    def display_collection
      review = StashDatacite::Resource::Review.new(@resource)
      render partial: 'stash_datacite/related_identifiers/collection', locals: { review: review, highlight_fields: [] }
    end

    def dupe_check
      dupes = []
      if @resource.title && @resource.title.length > 3
        other_submissions = params.key?(:admin) ? StashEngine::Resource.all : current_user.resources
        other_submissions = other_submissions.latest_per_dataset.where.not(identifier_id: @resource.identifier_id)
          .where("stash_engine_identifiers.pub_state != 'withdrawn'")
        primary_article = @resource.related_identifiers.find_by(work_type: 'primary_article')&.related_identifier
        manuscript = @resource.resource_publication&.manuscript_number
        dupes = other_submissions.where('LOWER(title) = LOWER(?)', @resource.title)&.select(:id, :title, :identifier_id).to_a
        if primary_article.present?
          dupes.concat(other_submissions.joins(:related_identifiers)
              .where(related_identifiers: { work_type: 'primary_article', related_identifier: primary_article })
              &.select(:id, :title, :identifier_id).to_a)
        end
        if manuscript&.match(/\d/)
          dupes.concat(
            other_submissions.joins(:resource_publication).where(resource_publication: { manuscript_number: manuscript })
            &.select(:id, :title, :identifier_id).to_a
          )
        end
      end
      @dupes = dupes.uniq
      respond_to do |format|
        format.js { render template: 'stash_engine/admin_datasets/dupe_check', formats: [:js] }
        format.json { render json: @dupes }
      end
    end
    # rubocop:enable Metrics/AbcSize

    # patch request
    # Saves the setting of the import type (manuscript, published, other).  While this is set on the identifier, put it
    # here because we already have the resource controller, including permission checking and no identifier controller.
    def import_type
      @resource.identifier.update(import_info: params[:import_info])
      render json: { import_info: params[:import_info] }, status: :ok
    end

    def license_agree
      @resource.identifier.update(license_id: params[:license_id])
      render json: { license_id: params[:license] }, status: :ok
    end

    def payer_check
      render json: {
        new_upload_size_limit: @resource.identifier.new_upload_size_limit
      }, status: :ok
    end

    private

    # We have parameters requesting to match to a Manuscript object; prefill journal info and import metadata if possible
    def import_manuscript_using_params(resource)
      return unless resource && params['journalID'] && params['manu']

      j = StashEngine::Journal.where(journal_code: params['journalID'].downcase).first
      return unless j

      # Save the journal and manuscript information in the dataset
      pub = StashEngine::ResourcePublication.find_or_create_by(resource_id: resource.id)
      pub.update({ publication_issn: j.single_issn, publication_name: j.title, manuscript_number: params['manu'] })

      # If possible, import existing metadata from the Manuscript objects into the dataset
      manu = StashEngine::Manuscript.where(journal: j, manuscript_number: params['manu']).first
      return unless manu

      dryad_import = Stash::Import::DryadManuscript.new(resource: resource, manuscript: manu)
      dryad_import.populate
    end

    def assign_resource
      @resource = resource
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.require(:resource).permit(:user_id, :current_resource_state_id)
    end

    def require_in_progress
      redirect_to choose_dashboard_path, alert: 'You may only edit the current version of the dataset' unless resource.current_state == 'in_progress'
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

# rubocop:enable Metrics/ClassLength

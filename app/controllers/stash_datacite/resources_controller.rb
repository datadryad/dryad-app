module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController
    protect_from_forgery

    include StashEngine::ApplicationHelper
    include ActionView::Helpers::NumberHelper

    before_action :set_page_info
    before_action :revalidate_submission, only: %i[submission]
    # get resources and composite information for in-progress table view

    include StashDatacite::LandingMixin

    def show
      respond_to do |format|
        format.js do
          setup_show_variables(params[:id]) # this method is from LandingMixin so it can be reused in StashEngine
        end
      end
    end

    # Review responds as a get request to review the resource before saving -- ajaxes into page when we thought multi schemas
    def review
      respond_to do |format|
        format.js do
          @resource = StashEngine::Resource.find(params[:id])
          @resource.cleanup_blank_models!
          check_required_fields(@resource)
          @review = Resource::Review.new(@resource)
          @resource.has_geolocation = @review.geolocation_data?
          if @resource.identifier.automatic_ppr? && @resource.identifier.date_last_curated.blank?
            @resource.hold_for_peer_review = true
          elsif !@resource.identifier.allow_review? || @resource.identifier.date_last_curated.present?
            @resource.hold_for_peer_review = false
            @resource.peer_review_end_date = nil
          end
          @resource.save!
          @resource.reload
          if @resource.identifier.payment_type.blank? || @resource.identifier.payment_type == 'unknown'
            @target_page = stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: @resource.id)
            @aff_tenant = StashEngine::Tenant.where(ror_id: @resource.owner_author.affiliations.map(&:ror_id)).connect_list.first
          end
        end
      end
    end

    def submission
      resource_cleanup
      ensure_license
      update_submission_resource_info(@resource)

      StashEngine.repository.submit(resource_id: @resource_id)

      @resource.curation_activities << StashEngine::CurationActivity.create(
        status: 'processing', note: 'Repository processing data', user_id: current_user&.id || 0
      )

      @resource.reload

      @resource.send_software_to_zenodo # this only does anything if software needs to be sent (new sfw or sfw in the past)
      @resource.send_supp_to_zenodo

      # There is a return URL for a simple case and backwards compatibility (only for for whole user and for journals).
      # There is also one for curators and need to return back to different pages/filter setting for each dataset they
      # edit in one of dozens of different windows at the same time, so needs to be specific to each dataset.
      if session["return_url_#{@resource.identifier_id}"] || session[:returnURL]
        return_url = session["return_url_#{@resource.identifier_id}"] || session[:returnURL]
        session["return_url_#{@resource.identifier_id}"] = nil
        session[:returnURL] = nil
        redirect_to(return_url, notice: "Submitted updates for #{@resource.identifier}, title: #{@resource.title}", allow_other_host: true)
      else
        redirect_to(stash_url_helpers.choose_dashboard_path(doi: @resource.identifier.identifier), notice: resource_submitted_message(@resource))
      end
    end

    private

    def update_submission_resource_info(resource)
      # Update default behaviors that may have been changed by API superusers.
      # In a production environment, updates through the UI reset these values
      # to their default (UI) settings.
      if Rails.env.include?('production')
        resource.update(skip_datacite_update: false, skip_emails: false,
                        preserve_curation_status: false, loosen_validation: false)
      end

      # hide readme on landing page if set by curator
      if params[:hide_readme]
        resource.update(display_readme: false)
      elsif !resource.display_readme
        resource.update(display_readme: true)
      end

      StashEngine::EditHistory.create(resource_id: resource.id, user_comment: params[:user_comment])

      # this is here because they want it in curation notes, in addition to the edit history table
      return if params[:user_comment].blank?

      last = resource.curation_activities.last
      StashEngine::CurationActivity.create(status: last.status, user_id: current_user.id, note: params[:user_comment],
                                           resource_id: last.resource_id)
    end

    def check_required_fields(resource)
      completions = Resource::Completions.new(resource)

      @completions = completions

      @error_items = Resource::DatasetValidations.new(resource: resource).errors
    end

    def resource_submitted_message(resource)
      identifier_uri = resource.identifier_uri
      msg = []
      msg << "#{resource.title || '(unknown title)'} submitted"
      msg << (identifier_uri ? "with DOI #{identifier_uri}." : '.')
      msg << 'There may be a delay for processing before the item is available.'
      msg.join(' ')
    end

    def processing?(resource)
      if (resource && resource.identifier && resource.identifier.processing?) || resource&.current_resource_state&.resource_state != 'in_progress'
        return true
      end

      resource.current_resource_state.update(resource_state: 'processing') # should lock them out of multiple rapid submissions of same resource
      false
    end

    def resource_cleanup
      @resource.cleanup_blank_models!
      @resource.current_state = 'processing'
      @resource.identifier.record_payment unless @resource.identifier.publication_date.present?
      @resource.check_add_readme_file
      @resource.check_add_cedar_json
    end

    def ensure_license
      return unless @resource.rights.empty?

      license = StashEngine::License.by_id(@resource.identifier.license_id)
      @resource.rights.create(rights: license[:name], rights_uri: license[:uri])
    end

    def revalidate_submission
      @resource_id = params[:resource_id]
      @resource = StashEngine::Resource.find(@resource_id)

      redirect_to stash_url_helpers.dashboard_path, alert: 'Invalid submission' and return unless @resource.present?

      @resource.identifier.update_search_words!

      error_items = Resource::DatasetValidations.new(resource: @resource, user: current_user).errors
      redirect_to stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: @resource.id), alert: error_items and return if error_items

      redirect_to stash_url_helpers.dashboard_path, alert: 'Dataset is already being submitted' if processing?(@resource)
    end
  end
end

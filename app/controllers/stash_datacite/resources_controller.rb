module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController
    protect_from_forgery except: %i[user_in_progress user_submitted]

    include StashEngine::ApplicationHelper
    include ActionView::Helpers::NumberHelper

    before_action :ajax_require_current_user, only: %i[user_in_progress user_submitted]
    before_action :set_page_info
    before_action :revalidate_submission, only: %i[submission]
    # get resources and composite information for in-progress table view

    include StashDatacite::LandingMixin
    def user_in_progress
      respond_to do |format|
        format.js do
          # paging first and using separate object for pager (resources) from display (@in_progress_lines) means
          # only a page of objects needs calculations for display rather than all objects in list.  However if we need
          # to sort on calculated fields for display we'll need to calculate all values, sort and use the array pager
          # form of kaminari instead (which will likely be slower).
          @resources = StashEngine::Resource.where(user_id: session[:user_id]).in_progress_only.order(updated_at: :desc).page(@page).per(@page_size)
          @in_progress_lines = @resources.map { |resource| DatasetPresenter.new(resource) }
        end
      end
    end

    def user_submitted
      respond_to do |format|
        format.js do
          return if current_user.blank?

          @resources = current_user.latest_completed_resource_per_identifier.order(updated_at: :desc).page(@page).per(@page_size)
          @submitted_lines = @resources.map { |resource| DatasetPresenter.new(resource) }
        end
      end
    end

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
          @resource.save!
        end
      end
    end

    def submission
      @resource.current_state = 'processing'
      @resource.check_add_readme_file

      update_submission_resource_info(@resource)

      StashEngine.repository.submit(resource_id: @resource_id)

      @resource.curation_activities << StashEngine::CurationActivity.create(status: 'processing', note: 'Repository processing data',
                                                                           user_id: current_user.id)

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
        redirect_to return_url, notice: "Submitted updates for #{@resource.identifier}, title: #{@resource.title}"
      else
        redirect_to(stash_url_helpers.dashboard_path, notice: resource_submitted_message(@resource))
      end
    end

    private

    def update_submission_resource_info(resource)
      # Update default behaviors that may have been changed by API superusers.
      # In a production environment, updates through the UI reset these values
      # to their default (UI) settings.
      if Rails.env == 'production'
        resource.update(skip_datacite_update: false, skip_emails: false,
                        preserve_curation_status: false, loosen_validation: false)
      end

      # write the software license to the database
      license_id = (params[:software_license].blank? ? 'MIT' : params[:software_license])
      id_for_license = StashEngine::SoftwareLicense.where(identifier: license_id).first&.id
      resource.identifier.update(software_license_id: id_for_license)

      # TODO: put this somewhere more reliable
      StashDatacite::DataciteDate.set_date_available(resource_id: resource.id)

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
        redirect_back(fallback_location: stash_url_helpers.dashboard_path,
                      notice: 'You may not submit this version of the dataset because a previous version has not finished ' \
                              'processing or you are trying to re-submit an old version')
        return true
      end
      resource.current_resource_state.update(resource_state: 'processing') # should lock them out of multiple rapid submissions of same resource
      false
    end

    def revalidate_submission
      @resource_id = params[:resource_id]
      @resource = StashEngine::Resource.find(@resource_id)

      redirect_to stash_url_helpers.dashboard_path, alert: 'Invalid submission' and return unless @resource.present?

      @resource.identifier.update_search_words!

      error_items = Resource::DatasetValidations.new(resource: @resource).errors
      redirect_to stash_url_helpers.review_resource_path(@resource) and return if error_items.count.positive?

      redirect_to stash_url_helpers.dashboard_path, alert: 'Dataset is already being submitted' if processing?(@resource)
    end
  end
end

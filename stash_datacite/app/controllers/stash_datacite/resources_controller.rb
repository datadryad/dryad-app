require_dependency 'stash_datacite/application_controller'

# require 'stash_datacite/merritt_packager'

module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController
    include StashEngine::ApplicationHelper
    include ActionView::Helpers::NumberHelper

    before_action :ajax_require_current_user, only: [:user_in_progress]
    before_action :set_page_info
    # get resources and composite information for in-progress table view

    include StashDatacite::LandingMixin
    def user_in_progress
      respond_to do |format|
        format.js do
          # paging first and using separate object for pager (resources) from display (@in_progress_lines) means
          # only a page of objects needs calculations for display rather than all objects in list.  However if we need
          # to sort on calculated fields for display we'll need to calculate all values, sort and use the array pager
          # form of kaminari instead (which will likely be slower).
          @resources = StashEngine::Resource.where(user_id: session[:user_id]).in_progress
            .order(updated_at: :desc).page(@page).per(@page_size)
          @in_progress_lines = @resources.map { |resource| DatasetPresenter.new(resource) }
        end
      end
    end

    def user_submitted
      respond_to do |format|
        format.js do
          # @resources = StashEngine::Resource.where(user_id: session[:user_id]).submitted.
          @resources = current_user.latest_completed_resource_per_identifier.order(updated_at: :desc)
            .page(@page).per(@page_size)
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

    # Review responds as a get request to review the resource before saving
    def review
      respond_to do |format|
        format.js do
          @resource = StashEngine::Resource.find(params[:id])
          check_required_fields(@resource)
          @review = Resource::Review.new(@resource)
          @resource.has_geolocation = @review.geolocation_data?
          @resource.save!
        end
      end
    end

    # TODO: move this to StashEngine
    def submission
      resource_id = params[:resource_id]
      StashEngine.repository.submit(resource_id: resource_id)

      # TODO: hard-code StashEngine::Resource everywhere instead of StashEngine::Resource
      resource = StashEngine::Resource.find(resource_id)

      redirect_to(stash_url_helpers.dashboard_path, notice: resource_submitted_message(resource))
    end

    private

    def max_submission_size
      current_tenant.max_submission_size.to_i
    end

    def max_version_size
      current_tenant.max_total_version_size.to_i
    end

    def max_file_count
      current_tenant.max_files.to_i
    end

    def check_required_fields(resource) # rubocop:disable Metrics/AbcSize
      completions = Resource::Completions.new(resource)
      warnings = completions.all_warnings
      warnings << submission_size_warning_message(max_submission_size) if completions.over_manifest_file_size?(max_submission_size)
      warnings << file_count_warning_message(max_file_count) if completions.over_manifest_file_count?(max_file_count)
      warnings << version_size_warning_message(max_version_size) if completions.over_version_size?(max_version_size)
      @completions = completions
      @data = warnings
    end

    def file_count_warning_message(count)
      format_count = number_with_delimiter(count, delimiter: ',')
      "Remove some files until you have a smaller file count than #{format_count} files"
    end

    def submission_size_warning_message(size)
      "Remove some files until you have a smaller dataset size than #{filesize(size)}"
    end

    def version_size_warning_message(size)
      "Remove some files until you have a smaller version size than #{filesize(size)}, or upload by URL instead."
    end

    def resource_submitted_message(resource)
      identifier_uri = resource.identifier_uri
      msg = []
      msg << "#{resource.title || '(unknown title)'} submitted"
      msg << (identifier_uri ? "with DOI #{identifier_uri}." : '.')
      msg << 'There may be a delay for processing before the item is available.'
      msg.join(' ')
    end

  end
end

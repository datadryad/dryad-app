require_dependency 'stash_datacite/application_controller'

#require 'stash_datacite/merritt_packager'

module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController
    before_action :ajax_require_current_user, only: [:user_in_progress]
    before_action :set_page_info
    # get resources and composite information for in-progress table view

    include StashDatacite::LandingMixin
    def user_in_progress
      respond_to do |format|
        format.js do
          #paging first and using separate object for pager (resources) from display (@in_progress_lines) means
          #only a page of objects needs calculations for display rather than all objects in list.  However if we need
          #to sort on calculated fields for display we'll need to calculate all values, sort and use the array pager
          #form of kaminari instead (which will likely be slower).
          @resources = StashDatacite.resource_class.where(user_id: session[:user_id]).in_progress
                                    .order(updated_at: :desc).page(@page).per(@page_size)
          @in_progress_lines = @resources.map { |resource| DatasetPresenter.new(resource) }
        end
      end
    end

    def user_submitted
      respond_to do |format|
        format.js do
          #@resources = StashDatacite.resource_class.where(user_id: session[:user_id]).submitted.
          @resources = current_user.latest_completed_resource_per_identifier.order(updated_at: :desc)
                                   .page(@page).per(@page_size)
          @submitted_lines = @resources.map { |resource| DatasetPresenter.new(resource) }
        end
      end
    end

    def show
      respond_to do |format|
        format.js do
          setup_show_variables(params[:id]) #this method is from LandingMixin so it can be reused in StashEngine
        end
      end
    end

    # Review responds as a get request to review the resource before saving
    def review
      respond_to do |format|
        format.js do
          @resource = StashDatacite.resource_class.find(params[:id])
          check_required_fields(@resource)
          @review = Resource::Review.new(@resource)
          if @review.no_geolocation_data
            @resource.has_geolocation = false
            @resource.save!
          end
        end
      end
    end

    # TODO: move this to StashEngine
    def submission
      resource_id = params[:resource_id]
      StashEngine::repository.submit(resource_id)

      # TODO: hard-code StashEngine::Resource everywhere instead of StashDatacite.resource_class
      resource = StashDatacite.resource_class.find(resource_id)

      notice = []
      notice << "#{resource.primary_title || '(unknown title)'} submitted"
      identifier_uri = resource.identifier_uri
      notice << (identifier_uri ? "with DOI #{identifier_uri}." : '.')
      notice << 'There may be a delay for processing before the item is available.'
      redirect_to stash_url_helpers.dashboard_path, notice: notice.join(' ')
    end

    private

    def main_title(resource)
      title = resource.titles.where(title_type: nil).first
      title.try(:title)
    end

  end
end

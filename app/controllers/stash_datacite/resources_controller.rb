require_dependency 'stash_datacite/application_controller'

require 'stash_datacite/merritt_packager'

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
          if @review.no_geolocation_data == true
            @resource.has_geolocation = false
            @resource.save!
          end
        end
      end
    end

    def submission
      resource = StashDatacite.resource_class.find(params[:resource_id])
      submit_async(resource)
      create_resource_state(resource)

      title = resource.titles.first
      identifier_str = resource.identifier_str

      notice = []
      notice << "#{title ? title.title : '(unknown title)'} submitted"
      notice << (identifier_str ? "with DOI #{identifier_str}." : '.')
      notice << 'There may be a delay for processing before the item is available.'

      redirect_to stash_url_helpers.dashboard_path, notice: notice.join(' ')
    end

    private

    def submit_async(resource)
      packager = StashDatacite::MerrittPackager.new(
        resource: resource,
        tenant: current_tenant,
        url_helpers: stash_url_helpers,
        request_host: request.host,
        request_port: request.port
      )
      resource.package_and_submit(packager)
    end

    def create_resource_state(resource)
      # TODO: why are we checking required fields after we already submitted?
      data = check_required_fields(resource)
      if data.nil?
        # TODO: let the background jobs take care of this
        unless resource.published? || resource.processing?
          resource.current_state = 'processing'
        end
      end
    end

    def main_title(resource)
      title = resource.titles.where(title_type: nil).first
      title.try(:title)
    end

  end
end

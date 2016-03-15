require_dependency 'stash_datacite/application_controller'

module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController
    before_action :ajax_require_current_user, only: [:user_in_progress]
    before_action :set_page_info

    # get resources and composite information for in-progress table view
    def user_in_progress
      respond_to do |format|
        format.js {
          #paging first and using separate object for pager (resources) from display (@in_progress_lines) means
          #only a page of objects needs calculations for display rather than all objects in list.  However if we need
          #to sort on calculated fields for display we'll need to calculate all values, sort and use the array pager
          #form of kaminari instead (which will likely be slower).
          @resources = StashDatacite.resource_class.where(user_id: session[:user_id]).page(@page).per(@page_size)
          @in_progress_lines = @resources.map { |resource| DatasetPresenter.new(resource) }
        }
      end
    end

    # Review responds as a get request to review the resource before saving
    def review
      respond_to do |format|
        format.js {
          @resource = StashDatacite.resource_class.find(params[:id])
          @resource_type = @resource.resource_type
          @title = @resource.titles.where(title_type: :main).first
          @creators =  @resource.creators
          @abstract = @resource.descriptions.where( description_type: :abstract ).first
          @methods = @resource.descriptions.where( description_type: :methods ).first
          @usage_notes = @resource.descriptions.where( description_type: :usage_notes ).first
          @subjects = @resource.subjects
          @contributors = @resource.contributors
          @related_identifiers = @resource.related_identifiers
          @file_uploads = @resource.file_uploads
          @geolocation_points = @resource.geolocation_points
          @geolocation_boxes = @resource.geolocation_boxes
          @geolocation_places = @resource.geolocation_places
        }
      end
    end
  end
end

require_dependency 'stash_datacite/application_controller'
module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController
    before_action :ajax_require_current_user, only: [:user_in_progress]

    # get resources and composite information for in-progress table view
    def user_in_progress
      #should require current user
      #respond_to do |format|
      #  format.js{
      @resources = StashDatacite.resource_class.where(user_id: session[:user_id])
                                .paginate(page: params[:page], per_page: 5)
      #  }
      #end
      @in_progress_lines = @resources.map { |resource| DatasetPresenter.new(resource) }

      respond_to do |format|
        format.js {
          page = params[:page] || '1'
          #paging first and using separate object for pager (resources) from display (@in_progress_lines) means
          #only a page of objects needs calculations for display rather than all objects in list.  However if we need
          #to sort on calculated fields for display we'll need to calculate all values, sort and use the array pager
          #form of kaminari instead (which will likely be slower).
          @resources = StashDatacite.resource_class.where(user_id: session[:user_id]).page(page).per(5)
          @in_progress_lines = @resources.map { |resource| DatasetPresenter.new(resource) }
        }
      end
    end
  end
end

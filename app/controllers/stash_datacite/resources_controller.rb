require_dependency "stash_datacite/application_controller"

module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController

    # get resources and composite information for in-progress table view
    def user_in_progress

      #should require current user

      #respond_to do |format|
      #  format.js{
          page = params[:page] || '5'
          @resources = StashDatacite.resource_class.where(user_id: session[:user_id])
          @in_progress_lines = @resources.map{|resource| DatasetPresenter.new(resource)}
          @display_lines = Kaminari.paginate_array(@in_progress_lines).page(page).per(5)
      #  }
      #end
    end

  end
end

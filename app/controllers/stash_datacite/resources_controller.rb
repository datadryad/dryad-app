require_dependency 'stash_datacite/application_controller'
module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController
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
    end
  end
end

require_dependency 'stash_engine/application_controller'

module StashEngine
  class EditHistoriesController < ApplicationController

    # we are really only showing a list of edit history for a resource and are not showing much else
    def index
      @resource = Resource.find(params[:resource_id])
      @presenters = [StashDatacite::ResourcesController::DatasetPresenter.new(@resource)]
      return unless @resource.identifier
    end
  end
end

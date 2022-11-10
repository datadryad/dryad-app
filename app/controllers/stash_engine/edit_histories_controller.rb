require 'stash_engine/application_controller'

module StashEngine
  class EditHistoriesController < ApplicationController

    helper SortableTableHelper

    # we are really only showing a list of edit history for a resource and are not showing much else
    def index
      @resource = Resource.find(params[:resource_id])
      @presenters = resources_in_dataset.map { |i| StashDatacite::ResourcesController::DatasetPresenter.new(i) }
    end

    private

    def resources_in_dataset
      return @resource.identifier.resources if @resource.identifier

      [@resource] # just this resource no other versions
    end

  end
end

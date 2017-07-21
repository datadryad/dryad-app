require_dependency 'stash_engine/application_controller'

module StashEngine
  class EditHistoriesController < ApplicationController

    # we are really only showing a list of edit history for a resource and are not showing much else
    def index
      @resource = Resource.find(params[:resource_id])
      @presenters = resources_in_dataset.map { |i| StashDatacite::ResourcesController::DatasetPresenter.new(i) }
      @sort_column = sort_column
      manual_sort!(@presenters, @sort_column)
    end

    private

    def resources_in_dataset
      return @resource.identifier.resources if @resource.identifier
      [@resource] # just this resource no other versions
    end

    def sort_column
      resource_created_at = SortableTable::SortColumnDefinition.new('resource_created_at')
      edited_by_name_w_role = SortableTable::SortColumnDefinition.new('edited_by_name_w_role')
      version = SortableTable::SortColumnDefinition.new('version')
      comment = SortableTable::SortColumnDefinition.new('comment')
      sort_table = SortableTable::SortTable.new([version, resource_created_at, edited_by_name_w_role, comment])
      sort_table.sort_column(params[:sort], params[:direction])
    end
  end
end

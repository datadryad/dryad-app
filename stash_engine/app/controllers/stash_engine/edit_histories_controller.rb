require_dependency 'stash_engine/application_controller'

module StashEngine
  class EditHistoriesController < ApplicationController

    include StashEngine::Concerns::Sortable

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
      sort_table = SortableTable::SortTable.new(
        [sort_column_definition('resource_created_at', 'stash_engine_resources', %w[create_at]),
         sort_column_definition('edited_by_name_w_role', 'stash_engine_users', %w[last_name first_name]),
         sort_column_definition('version', 'stash_engine_resources', %w[version]),
         sort_column_definition('comment', 'stash_engine_resources', %w[comment])]
      )
      sort_table.sort_column(params[:sort], params[:direction])
    end
  end
end

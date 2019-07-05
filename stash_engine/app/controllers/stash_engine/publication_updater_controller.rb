require_dependency 'stash_engine/application_controller'

module StashEngine
  class PublicationUpdaterController < ApplicationController

    include SharedSecurityController
    include StashEngine::Concerns::Sortable

    before_action :require_admin
    before_action :setup_paging, only: [:index]
    before_action :setup_ds_sorting, only: [:index]

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    def index
      proposed_changes = StashEngine::ProposedChange.where(approved: false)
      @resources = StashEngine::Resource.latest_per_dataset.where(identifier_id: proposed_changes.map(&:identifier_id))
      @proposed_changes = proposed_changes.order(@sort_column.order).page(@page).per(@page_size)
    end

    def update
      redirect_to 'index'
    end

    def destroy
      redirect_to 'index'
    end

    private

    def proposed_change_params
      params.require(:proposed_change).permit(:id)
    end

    def setup_paging
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end

    def setup_ds_sorting
      sort_table = SortableTable::SortTable.new(
        [sort_column_definition('title', 'stash_engine_proposed_changes', %w[title]),
         sort_column_definition('publiction_name', 'stash_engine_proposed_changes', %w[publiction_name]),
         sort_column_definition('publiction_issn', 'stash_engine_proposed_changes', %w[publiction_issn]),
         sort_column_definition('publiction_doi', 'stash_engine_proposed_changes', %w[publiction_doi]),
         sort_column_definition('publiction_date', 'stash_engine_proposed_changes', %w[publiction_date]),
         sort_column_definition('authors', 'stash_engine_proposed_changes', %w[authors]),
         sort_column_definition('provenance', 'stash_engine_proposed_changes', %w[provenance]),
         sort_column_definition('score', 'stash_engine_proposed_changes', %w[score])]
      )
      @sort_column = sort_table.sort_column(params[:sort], params[:direction])
    end

  end
end

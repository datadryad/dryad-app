require_dependency 'stash_engine/application_controller'

module StashEngine
  class PublicationUpdaterController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_superuser
    before_action :setup_paging, only: [:index]

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    def index
      proposed_changes = StashEngine::ProposedChange.includes(identifier: :resources)
        .joins(identifier: :resources).where(approved: false, rejected: false)
      params[:sort] = 'score' if params[:sort].blank?
      params[:direction] = 'desc' if params[:direction].blank?
      @proposed_changes = proposed_changes.order(helpers.sortable_table_order).page(@page).per(@page_size)
      return unless @proposed_changes.present?

      @resources = StashEngine::Resource.latest_per_dataset.where(identifier_id: @proposed_changes&.map(&:identifier_id))
    end

    def update
      respond_to do |format|
        @proposed_change = StashEngine::ProposedChange.find(params[:id])
        @resource = @proposed_change.identifier&.latest_resource if @proposed_change.present?
        @proposed_change.approve!(current_user: current_user)
        @proposed_change.reload
        format.js
      end
    end

    def destroy
      respond_to do |format|
        @proposed_change = StashEngine::ProposedChange.find(params[:id])
        @resource = @proposed_change.identifier&.latest_resource if @proposed_change.present?
        @proposed_change.reject!(current_user: current_user)
        @proposed_change.reload
        format.js
      end
    end

    private

    def setup_paging
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end

  end
end

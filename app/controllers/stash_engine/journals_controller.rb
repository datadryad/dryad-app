module StashEngine
  class JournalsController < ApplicationController

    helper SortableTableHelper

    def index
      params.permit(:q)
      params[:sort] = 'title' if params[:sort].blank?
      integrated_journals = StashEngine::Journal.where.not(integrated_at: nil).select(:id).map(&:id)
      sponsoring_journals = StashEngine::Journal.sponsoring.select(:id).map(&:id)
      display_journals = integrated_journals | sponsoring_journals

      ord = helpers.sortable_table_order(whitelist: %w[title payment_plan sponsor_id parent_org_id default_to_ppr manuscript_number])
      @journals = Journal.left_outer_joins(:sponsor, :payment_configuration, :manuscripts).where(id: display_journals).order(ord, title: :asc)
        .preload(:sponsor).preload(:issns)

      respond_to(&:html)
    end
  end
end

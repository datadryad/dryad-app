module StashEngine
  class JournalsController < ApplicationController

    helper SortableTableHelper

    def index
      params.permit(:q)
      params[:sort] = 'title' if params[:sort].blank?
      @metadata_journals = StashEngine::Journal.joins(:manuscripts)
        .where("stash_engine_manuscripts.created_at > '#{1.year.ago.iso8601}'").select(:id).distinct.map(&:id)
      @api_journals = StashEngine::Journal.api_journals.map(&:id)
      sponsoring_journals = StashEngine::Journal.where(payment_plan_type: %w[SUBSCRIPTION PREPAID DEFERRED TIERED 2025]).select(:id).map(&:id)
      display_journals = @metadata_journals | sponsoring_journals | @api_journals

      ord = helpers.sortable_table_order(whitelist: %w[title payment_plan_type sponsor_id parent_org_id default_to_ppr])
      @journals = Journal.left_outer_joins(:sponsor).where(id: display_journals).order(ord, title: :asc)
        .preload(:sponsor).preload(:issns)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=journals_#{Time.new.strftime('%F')}.csv"
        end
      end
    end
  end
end

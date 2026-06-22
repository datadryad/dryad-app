module StashEngine
  class JournalsController < ApplicationController

    helper SortableTableHelper

    def index
      params.permit(:q)
      params[:sort] = 'title' if params[:sort].blank?

      ord = helpers.sortable_table_order(whitelist: %w[title payment_plan sponsor_id root_org_id default_to_ppr integrated_at])

      @journals = Journal.with_sponsorship.where("payment_plan is not null or integrated_at >= '#{2.years.ago}'").order(ord, title: :asc)
        .preload(:sponsor).preload(:issns)

      respond_to(&:html)
    end
  end
end

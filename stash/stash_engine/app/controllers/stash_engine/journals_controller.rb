require_dependency 'stash_engine/application_controller'

module StashEngine
  class JournalsController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    def index
      params.permit(:q)

      @all_journals = Journal.all
      @journals = Journal.joins(:sponsor).where.not(payment_plan_type: [nil, '']).order(helpers.sortable_table_order, id: :asc)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=journals_#{Time.new.strftime('%F')}.csv"
        end
      end
    end
  end
end

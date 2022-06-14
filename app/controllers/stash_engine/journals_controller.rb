require_dependency 'stash_engine/application_controller'

module StashEngine
  class JournalsController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_curator

    def index
      params.permit(:q)
      params[:sort] = 'title' if params[:sort].blank?
      @all_journals = Journal.all

      metadata_journal_clause = 'stash_engine_journals.id IN ' \
                                "(select distinct journal_id from stash_engine_manuscripts where created_at > '#{1.year.ago.iso8601}')"
      metadata_journals = Journal.where(metadata_journal_clause).map(&:id)
      sponsoring_journals = Journal.where.not(payment_plan_type: [nil, '']).map(&:id)
      display_journals = metadata_journals | sponsoring_journals

      @journals = Journal.joins(:sponsor).where(id: display_journals).order(helpers.sortable_table_order, title: :asc)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=journals_#{Time.new.strftime('%F')}.csv"
        end
      end
    end
  end
end

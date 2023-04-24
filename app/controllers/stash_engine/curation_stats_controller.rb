module StashEngine
  class CurationStatsController < ApplicationController
    helper SortableTableHelper

    def index
      params.permit(:format)

      @all_stats = authorize CurationStats.all
      @current_stats = authorize CurationStats.where(date: 1.month.ago..Date.today).order('date DESC')

      @admin_stats = authorize StashEngine::AdminDatasetsController::Stats.new
      @admin_stats_3day = authorize StashEngine::AdminDatasetsController::Stats.new(untouched_since: Time.now - 3.days)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=curation_stats_#{Time.new.strftime('%F')}.csv"
        end
      end
    end
  end
end

module StashEngine
  class CurationStatsController < ApplicationController
    before_action :require_user_login
    helper SortableTableHelper

    def index
      params.permit(:format)

      @all_stats = authorize CurationStats.all
      @current_stats = authorize CurationStats.where(date: 1.month.ago..Time.now.utc.to_date).order('date DESC')

      @admin_stats = authorize StashEngine::AdminDatasetsController::Stats.new, policy_class: CurationStatsPolicy
      @admin_stats_3day = authorize StashEngine::AdminDatasetsController::Stats.new(
        untouched_since: Time.new.utc - 3.days
      ), policy_class: CurationStatsPolicy

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=curation_stats_#{Time.new.strftime('%F')}.csv"
        end
      end
    end
  end
end

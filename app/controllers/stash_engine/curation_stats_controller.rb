require 'stash_engine/application_controller'

module StashEngine
  class CurationStatsController < ApplicationController
    before_action :require_admin

    include SharedSecurityController
    helper SortableTableHelper

    def index
      params.permit(:format)

      @all_stats = CurationStats.all
      @current_stats = CurationStats.where(date: 1.month.ago..Date.today).order('date DESC')

      @admin_stats = StashEngine::AdminDatasetsController::Stats.new
      @admin_stats_2day = StashEngine::AdminDatasetsController::Stats.new(untouched_since: Time.now - 2.days)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=curation_stats_#{Time.new.strftime('%F')}.csv"
        end
      end
    end
  end
end

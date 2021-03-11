require_dependency 'stash_engine/application_controller'

module StashEngine
  class CurationStatsController < ApplicationController
    before_action :require_admin

    include SharedSecurityController
    helper SortableTableHelper

    def index
      params.permit(:format)

      @all_stats = CurationStats.all
      @stats = CurationStats.where(date: 1.month.ago..Date.today)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=curation_stats_#{Time.new.strftime('%F')}.csv"
        end
      end
    end
  end
end

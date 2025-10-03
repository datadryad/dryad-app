require 'csv'

module StashEngine
  class CurationStatsController < ApplicationController
    before_action :require_user_login
    helper SortableTableHelper
    helper AdminHelper

    def index
      params.permit(:format)
      @current_stats = authorize CurationStats.where(date: 1.month.ago..Time.now.utc.to_date).order('date DESC')

      @admin_stats = authorize StashEngine::AdminDatasetsController::Stats.new, policy_class: CurationStatsPolicy
      @admin_stats_3day = authorize StashEngine::AdminDatasetsController::Stats.new(
        untouched_since: Time.new.utc - 3.days
      ), policy_class: CurationStatsPolicy

      respond_to do |format|
        format.html
        format.csv do
          helpers.csv_headers('DryadCurationStats')
          self.response_body = csv_enumerator
        end
      end
    end

    def csv_enumerator
      Enumerator.new do |rows|
        rows << [
          'Date', 'Queue size', 'Unclaimed', 'Created', 'New to queue', 'New to PPR', 'PPR to Queue', 'PPR size',
          'Curation to AAR', 'AAR size', 'Curation to published', 'Withdrawn', 'Author revised', 'Author versioned'
        ].to_csv(row_sep: "\r\n")
        CurationStats.order(:date).find_each do |stat|
          row = [
            stat.date,
            stat.datasets_to_be_curated,
            stat.datasets_unclaimed,
            stat.new_datasets,
            stat.new_datasets_to_submitted,
            stat.new_datasets_to_peer_review,
            stat.ppr_to_curation,
            stat.ppr_size,
            stat.datasets_to_aar,
            stat.aar_size,
            stat.datasets_to_published,
            stat.datasets_to_withdrawn,
            stat.author_revised,
            stat.author_versioned
          ]
          rows << row.to_csv(row_sep: "\r\n")
        end
      end
    end
  end
end

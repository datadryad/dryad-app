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

    def charts
      authorize StashEngine::CurationStats, policy_class: CurationStatsPolicy

      fields = chart_fields
      @field_names = fields.values
      @field_keys = fields.keys

      set_monthly_chart
      set_daily_chart
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

    private

    def chart_fields
      {
        datasets_to_be_curated: 'Queue size',
        datasets_unclaimed: 'Unclaimed',
        new_datasets: 'Created',
        new_datasets_to_submitted: 'New to queue',
        new_datasets_to_peer_review: 'New to PPR',
        ppr_to_curation: 'PPR to Queue',
        ppr_size: 'PPR size',
        datasets_to_aar: 'Curation to AAR',
        aar_size: 'AAR size',
        datasets_to_published: 'Curation to published',
        datasets_to_withdrawn: 'Withdrawn',
        author_revised: 'Author revised',
        author_versioned: 'Author versioned'
      }
    end

    def set_monthly_chart
      start_date = 1.year.ago.beginning_of_month.beginning_of_day
      end_date = Date.today.end_of_month.end_of_day
      monthly_query = CurationStats
        .where(date: start_date..end_date)
        .group("DATE_FORMAT(date, '%Y-%m')")
        .select("DATE_FORMAT(date, '%Y-%m') AS month", *@field_keys.map { |f| "SUM(#{f}) AS #{f}" })

      @monthly_data = monthly_query.map do |row|
        { period: row.month }.merge(@field_keys.index_with { |f| row.send(f) })
      end
      @monthly_data = @monthly_data.sort_by { |a| a[:period] }
    end

    def set_daily_chart
      @start_day = params[:start_day].presence || 1.month.ago
      @end_day = params[:end_day].presence || Date.today

      daily_query = CurationStats
        .where(date: @start_day..@end_day)
        .group("DATE_FORMAT(date, '%Y-%m-%d')")
        .select("DATE_FORMAT(date, '%Y-%m-%d') AS day", *@field_keys.map { |f| "SUM(#{f}) AS #{f}" })

      @daily_data = daily_query.map do |row|
        { period: row.day }.merge(@field_keys.index_with { |f| row.send(f) })
      end
      @daily_data = @daily_data.sort_by { |a| a[:period] }
    end
  end
end

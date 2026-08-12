module StashEngine
  class AdminReportsController < ApplicationController
    helper SortableTableHelper

    before_action :set_page_info

    def index
      authorize Report

      @reports = Report
      apply_filters

      params[:direction] ||= 'desc'
      ord = helpers.sortable_table_order(whitelist: %w[created_at])
      @reports = @reports.order(ord)
      @reports = @reports.page(@page).per(@page_size)
    end

    private

    def apply_filters
      @filters = filter_params

      @reports = @reports.where('LOWER(title) LIKE LOWER(?)', "%#{@filters[:q]}%") if @filters[:q].present?
      @reports = @reports.where('report_type = ?', @filters[:report_type_filter]) if @filters[:report_type_filter].present?
      @reports = @reports.where('status = ?', @filters[:status_filter]) if @filters[:status_filter].present?
    end

    def set_page_info
      @page = filter_params[:page]
      @page_size = filter_params[:page_size]
    end

    def filter_params
      params.permit(
        :q,
        :report_type_filter,
        :status_filter,
        :page,
        :page_size
      )
    end
  end
end

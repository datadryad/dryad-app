require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminFundersController < ApplicationController
    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_admin
    # before_action :setup_paging, only: [:index]

    def index
      @rep = Report.new
      @rep.add_limit(offset: 0, rows: 100)

      # WHERE conditions
      @rep.add_where(arr: ['last_res.tenant_id = ?', params[:tenant]]) if params[:tenant].present?
      @rep.add_where(arr: ['contrib.contributor_name = ?', params[:funder_name]]) if params[:funder_name].present?
      add_date_range
      add_sort_order


      @funder_table = @rep.do_query
    end

    private def add_date_range
      # has a date type and at least one date in a range
      if params[:date_type].present? && (params[:start_date].present? || params[:end_date].present?)
        start_time = (params[:start_date].present? ? Time.parse(params[:start_date]) : Time.new(-1000, 1, 1) )
        end_time = (params[:end_date].present? ? Time.parse(params[:end_date]) : Time.new(3000, 1, 1) )
        if params[:date_type] == 'initial'
          @rep.add_where(arr: ['init_sub_date BETWEEN ? and ?', start_time, end_time])
        elsif params[:date_type] == 'published'
          @rep.add_where(arr: ['viewable_resource.publication_date BETWEEN ? and ?', start_time, end_time])
        end
      end
    end

    private def add_sort_order
      # order the list only by the whitelist, which creates partial SQL and eliminates injection
      ord = helpers.sortable_table_order(whitelist: %w[title authors identifier contributor_name award_number
                init_sub_date publication_date1 publication_date2])
      ord.gsub!(/publication_date\d/, 'publication_date')
      @rep.order(order_str: ord)
    end


  end
end

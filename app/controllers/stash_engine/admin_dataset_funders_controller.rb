require 'stash_engine/application_controller'

module StashEngine
  class AdminDatasetFundersController < ApplicationController
    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_admin

    def index
      setup_paging

      @rep = Report.new # the AdminFundersController::Report is where most of the complicated SQL is for this
      @rep.add_limit(offset: (@page - 1) * @page_size, rows: @page_size + 1) # add 1 to page size so it will have next page

      # WHERE conditions
      # Limit to tenant by either role or selected limit
      @role_limit = (%w[admin tenant_curator].include?(current_user.role) ? current_user.tenant_id : nil)
      tenant_limit = @role_limit || params[:tenant]
      @rep.add_where(arr: ['last_res.tenant_id = ?', tenant_limit]) if tenant_limit.present?

      add_funder_limit
      add_date_range
      add_sort_order

      @funder_table = @rep.do_query
      @funder_table = kaminari_pad(results_arr: @funder_table) # pads out results so kaminari displays paging correctly

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=#{Time.new.strftime('%F')}_funder_report.csv"
        end
      end
    end

    # this may add a special aggregate funder like NIH that has many sub-funders or may be no hierarchy
    private def add_funder_limit
      return unless params[:funder_name].present?

      group_record = StashDatacite::ContributorGrouping.where(name_identifier_id: params[:funder_id]).first
      if group_record.present?
        names = group_record.json_contains.map { |i| i['contributor_name'] } + [params[:funder_name]]
        sql = "contrib.contributor_name IN (#{names.map { |_i| '?' }.join(', ')})"
        @rep.add_where(arr: ([sql] + names).flatten) # should already be flat, but just in case
        return
      end

      @rep.add_where(arr: ['contrib.contributor_name = ?', params[:funder_name]]) # simple funder
    end

    private def setup_paging
      if request.format.csv?
        @page = 1
        @page_size = 1_000_000
        return
      end
      @page = (params[:page] || '1').to_i
      @page_size = if params[:page_size].blank? || params[:page_size].to_i == 0
                     10
                   else
                     params[:page_size].to_i
                   end
    end

    private def add_date_range
      # has a date type and at least one date in a range
      return unless params[:date_type].present? && (params[:start_date].present? || params[:end_date].present?)

      start_time = (params[:start_date].present? ? Time.parse(params[:start_date]) : Time.new(-1000, 1, 1))
      end_time = (params[:end_date].present? ? Time.parse(params[:end_date]) : Time.new(3000, 1, 1))
      case params[:date_type]
      when 'initial'
        @rep.add_where(arr: ['init_sub_date BETWEEN ? and ?', start_time, end_time])
      when 'published'
        @rep.add_where(arr: ['viewable_resource.publication_date BETWEEN ? and ?', start_time, end_time])
      end
    end

    private def add_sort_order
      # order the list only by the whitelist, which creates partial SQL and eliminates injection
      ord = helpers.sortable_table_order(whitelist: %w[title authors identifier contributor_name award_number
                                                       init_sub_date publication_date1 publication_date2])
      ord.gsub!(/publication_date\d/, 'publication_date')
      @rep.order(order_str: ord)
    end

    # pads out results so the kaminari page works right with SQL query
    private def kaminari_pad(results_arr:)
      # paginate for display
      blank_results = (@page.to_i - 1) * @page_size.to_i
      items = Array.new(blank_results, nil) + results_arr # pad out an array with empty results for earlier pages for kaminari
      Kaminari.paginate_array(items, total_count: items.length).page(@page).per(@page_size)
    end

  end
end

require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminFundersController < ApplicationController
    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_admin
    # before_action :setup_paging, only: [:index]

    def index
      rep = Report.new
      rep.add_limit(offset: 0, rows: 100)

      # order the list only by the whitelist, which creates partial SQL and eliminates injection
      ord = helpers.sortable_table_order(whitelist: %w[title authors identifier contributor_name award_number
                init_sub_date publication_date1 publication_date2])
      ord.gsub!(/publication_date\d/, 'publication_date')
      rep.order(order_str: ord)

      @funder_table = rep.do_query
    end

  end
end

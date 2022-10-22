require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminFundersController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_admin

    def index
      rep = Report.new
      rep.add_limit(offset: 0, rows: 100)
      @funder_table = rep.do_query
      byebug
      # :-(  it's not working right for dates
    end

  end
end

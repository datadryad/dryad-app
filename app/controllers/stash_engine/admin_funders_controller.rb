require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminFundersController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_admin

    def index
    end

  end
end

require_dependency 'stash_engine/application_controller'

module StashEngine
  class DashboardController < ApplicationController
    def show
      @resources = Resource.all
      @titles = StashDatacite::Title.all
    end
  end
end

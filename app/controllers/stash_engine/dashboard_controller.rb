require_dependency 'stash_engine/application_controller'

module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: [:show]
    before_action :force_to_domain, only: [:show]

    def show
    end

    def metadata_basics
    end

    def preparing_to_submit
    end

    def upload_basics
    end
  end
end

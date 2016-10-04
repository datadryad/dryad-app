require_dependency 'stash_engine/application_controller'

module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: [:show]
    before_action :force_to_domain, only: [:show]

    def getting_started
      respond_to do |format|
        unless current_user
          @resources = Resource.where(user_id: current_user.id)
            if @resources.present?
              redirect_to stash_url_helpers.dashboard_path && return
            else
              format.html
            end
        else
          format.html
        end
      end
    end

    def show
    end

    def metadata_basics
    end

    def preparing_to_submit
    end

    def upload_basics
    end

    # an AJAX wait to allow in-progress items to complete before continuing.
    def ajax_wait
      respond_to do |format|
        format.js do
          sleep 0.1
          head :ok, content_type: 'application/javascript'
        end
      end
    end
  end
end

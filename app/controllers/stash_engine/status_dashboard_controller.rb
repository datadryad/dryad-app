# frozen_string_literal: true

# Administrative console that displays the statuses of external dependencies
module StashEngine
  class StatusDashboardController < ApplicationController

    include SharedController
    before_action :require_user_login

    # NOTE: that this is a bit confusing since it service checks tied in from various strange places.

    # An item must have something entered into the stash_engine_external_dependencies to run checks.  It also uses the
    # similar model ExternalDependency in StashEngine.  It also has specific checks for the dependency in the directory
    # app/services/stash_engine/status_dashboard/<service-name>.rb that does the actual check and sets a value for it.
    def show
      authorize StashEngine::ExternalDependency.all
      @main_documentation = 'https://github.com/datadryad/dryad-app/tree/main/documentation'
      @managed_dependencies = StashEngine::ExternalDependency.where(internally_managed: true).order(:name)
      @unmanaged_dependencies = StashEngine::ExternalDependency.where(internally_managed: false).order(:name)
      @latest_check = StashEngine::ExternalDependency.where.not(status: 2).limit(1).first
        .updated_at.localtime
    end

  end
end

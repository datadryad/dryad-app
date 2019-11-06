# frozen_string_literal: true

# Administrative console that displays the statuses of external dependencies
module StashEngine
  class StatusDashboardController < ApplicationController

    def show
      @main_documentation = 'https://confluence.ucop.edu/display/Stash/Dryad+Operations'
      @managed_dependencies = StashEngine::ExternalDependency.where(internally_managed: true).order(:name)
      @unmanaged_dependencies = StashEngine::ExternalDependency.where(internally_managed: false).order(:name)
      @latest_check = StashEngine::ExternalDependency.where.not(status: 2).limit(1).first
        .updated_at.localtime.strftime('%b %e %I:%M%p')
    end

  end
end

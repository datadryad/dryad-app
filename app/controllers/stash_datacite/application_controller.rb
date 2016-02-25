module StashDatacite
  class ApplicationController < ::ApplicationController
    helper_method :stash_url_helpers, :current_tenant, :current_user

    delegate :current_tenant, :current_user, to: 'StashEngine::ApplicationController'

    def stash_url_helpers
      StashEngine::Engine.routes.url_helpers
    end

  end
end

module StashEngine
  class ApplicationController < ::ApplicationController
    helper_method :current_tenant

    def stash_datacite
      StashDatacite::Engine.routes.url_helpers
    end

    # get the current tenant for customizations, also deals with login
    def current_tenant
      if session[:test_domain]
        StashEngine::Tenant.by_domain(session[:test_domain])
      else
        StashEngine::Tenant.by_domain(request.host)
      end
    end
  end
end

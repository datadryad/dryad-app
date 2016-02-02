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

    def current_user
      @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    end

    def clear_user
      current_user = nil
    end

    def require_login
      if !current_user
        redirect_to tenants_path
      end
    end
  end
end

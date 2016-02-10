module StashEngine
  class ApplicationController < ::ApplicationController
    helper_method :current_tenant, :current_user

    def stash_datacite
      StashDatacite::Engine.routes.url_helpers
    end

    # get the current tenant for customizations, also deals with login
    def current_tenant
      if current_user
        StashEngine::Tenant.find(current_user.tenant_id)
      elsif session[:test_domain]
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
        flash[:alert] = "You must be logged in"
        redirect_to tenants_path
      end
    end

    def require_resource_owner
      if current_user.id != @resource.user_id
        flash[:alert] = "You do not have permission to view this resource"
        redirect_to tenants_path
      end
    end
  end
end

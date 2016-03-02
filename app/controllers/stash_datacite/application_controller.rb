module StashDatacite
  class ApplicationController < ::ApplicationController
    helper_method :stash_url_helpers, :current_tenant, :current_user
    def stash_url_helpers
      StashEngine::Engine.routes.url_helpers
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
      @current_user ||= StashEngine::User.find_by_id(session[:user_id]) if session[:user_id]
    end

    def ajax_require_current_user
      return false unless @current_user
    end

    # this sets up the page variables for use with kaminari paging
    def set_page_info
      @page = params[:page] || '1'
      @page_size = params[:page_size] || '5'
    end
  end
end

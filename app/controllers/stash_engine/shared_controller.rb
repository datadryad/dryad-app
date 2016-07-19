module StashEngine
  module SharedController
    require 'uri'
    require 'securerandom'
    #helper_method :current_tenant, :current_user, :metadata_engine, :metadata_url_helpers

    def metadata_url_helpers
      metadata_engine::Engine.routes.url_helpers
    end

    def stash_url_helpers
      StashEngine::Engine.routes.url_helpers
    end

    def discovery_url_helpers
      StashDiscovery::Engine.routes.url_helpers
    end

    # discovery engine isn't namespaced because of blacklight/geoblackight, so "main_app" will work for it.

    # get the current tenant for submission
    def current_tenant
      if current_user
        StashEngine::Tenant.find(current_user.tenant_id)
      elsif session[:test_domain]
        StashEngine::Tenant.by_domain(session[:test_domain])
      else
        StashEngine::Tenant.by_domain(request.host)
      end
    end

    # get the current tenant for display elements, only, ignores logged in
    def current_tenant_display
      if session[:test_domain]
        StashEngine::Tenant.by_domain(session[:test_domain])
      else
        StashEngine::Tenant.by_domain(request.host)
      end
    end

    # get current tenant, only based on the domain
    def current_tenant_simple
      StashEngine::Tenant.by_domain_w_nil(request.host)
    end

    def current_user
      @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    end

    def metadata_engine
      StashEngine.app.metadata_engine.constantize
    end

    def clear_user
      @current_user = nil
    end

    def require_login
      return if current_user
      flash[:alert] = 'You must be logged in.'
      redirect_to current_tenant_simple.try(:omniauth_login_path)
    end

    def require_resource_owner
      if current_user.id != @resource.user_id
        flash[:alert] = 'You do not have permission to modify this dataset.'
        redirect_to stash_engine.dashboard_path
      end
    end

    def ajax_require_current_user
      return false unless @current_user
    end

    # this sets up the page variables for use with kaminari paging
    def set_page_info
      @page = params[:page] || '1'
      @page_size = params[:page_size] || '5'
    end

    # helper to generate URL for landing page for an identifier with currently logged-in tenant
    def landing_url(identifier)
      current_tenant.landing_url(stash_url_helpers.show_path(identifier))
    end

    # make suffix number making ids in html forms
    def field_suffix(object)
      if object && object.id
        "_#{object.id}"
      else
        "_#{SecureRandom.uuid}"
      end
    end

    # make logo_string for image_tag per tenant
    def logo_path(hsh)
      test_path = File.join(Rails.root, 'app', 'assets', 'images', 'tenants')
      base_fn = "logo_#{current_tenant.tenant_id}"
      ['.svg', '.png', '.jpg'].each do |ext|
        if File.exists?(File.join(test_path, "#{base_fn}#{ext}"))
          return view_context.image_tag "tenants/#{base_fn}#{ext}",
                                 hsh.merge({alt: "#{current_tenant.long_name} logo"})
        end
      end
    end
  end
end

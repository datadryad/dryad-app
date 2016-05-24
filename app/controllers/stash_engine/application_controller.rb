module StashEngine
  class ApplicationController < ::ApplicationController
    helper_method :current_tenant, :current_user, :metadata_engine, :metadata_url_helpers, :stash_url_helpers,
                  :landing_url, :discovery_url_helpers, :field_suffix, :current_tenant_simple

    include SharedController

    prepend_view_path("#{Rails.application.root}/app/views")

    def force_to_domain
      unless session[:test_domain] || request.host == current_tenant_display.full_domain
        uri = URI(request.original_url)
        uri.host = current_tenant_display.full_domain
        redirect_to uri.to_s and return
      end
    end

  end
end

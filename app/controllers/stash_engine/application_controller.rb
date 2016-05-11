module StashEngine
  class ApplicationController < ::ApplicationController
    helper_method :current_tenant, :current_user, :metadata_engine, :metadata_url_helpers, :stash_url_helpers,
                  :landing_url, :discovery_url_helpers

    include SharedController

    prepend_view_path("#{Rails.application.root}/app/views")
  end
end

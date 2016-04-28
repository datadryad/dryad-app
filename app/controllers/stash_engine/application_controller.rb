module StashEngine
  class ApplicationController < ::ApplicationController
    helper_method :current_tenant, :current_user, :metadata_engine, :metadata_url_helpers, :stash_url_helpers,
                  :landing_url

    include SharedController

    prepend_view_path("#{Rails.application.root}/app/views")
  end
end

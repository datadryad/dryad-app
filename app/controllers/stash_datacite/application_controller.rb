module StashDatacite
  class ApplicationController < ::ApplicationController
    helper_method :current_tenant, :current_user, :metadata_engine, :metadata_url_helpers, :stash_url_helpers,
                  :landing_url, :field_suffix, :current_tenant_simple, :logo_path

    helper StashEngine::ApplicationHelper

    include StashEngine::SharedController
  end
end

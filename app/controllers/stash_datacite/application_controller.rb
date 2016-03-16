module StashDatacite
  class ApplicationController < ::ApplicationController
    helper_method :current_tenant, :current_user, :metadata_engine, :metadata_url_helpers, :stash_url_helpers

    helper StashEngine::ApplicationHelper

    include StashEngine::SharedController

    include StashEngine::SharedController
  end
end

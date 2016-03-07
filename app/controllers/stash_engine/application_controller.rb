module StashEngine
  class ApplicationController < ::ApplicationController
    helper_method :current_tenant, :current_user, :metadata_engine, :metadata_url_helpers, :stash_url_helpers

    include SharedController

  end
end

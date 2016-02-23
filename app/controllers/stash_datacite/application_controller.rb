module StashDatacite
  class ApplicationController < ::ApplicationController
    helper_method :stash_url_helpers

    def stash_url_helpers
      StashEngine::Engine.routes.url_helpers
    end

  end
end

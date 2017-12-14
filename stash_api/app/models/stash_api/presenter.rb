module StashApi
  module Presenter

    def api_url_helper
      StashApi::Engine.routes.url_helpers
    end

  end
end

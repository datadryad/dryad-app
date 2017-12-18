module StashApi
  module Presenter

    def self.included(base)
      def base.api_url_helper
        StashApi::Engine.routes.url_helpers
      end
    end

    def api_url_helper
      self.class.api_url_helper
    end

  end
end

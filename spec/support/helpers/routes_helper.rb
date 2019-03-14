module RoutesHelper

  def stash_url_helpers
    StashEngine::Engine.routes.url_helpers
  end

end

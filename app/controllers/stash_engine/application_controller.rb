class StashEngine::ApplicationController < ApplicationController

  def stash_datacite
    StashDatacite::Engine.routes.url_helpers
  end

end
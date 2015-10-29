class StashEngine::ApplicationController < ApplicationController

  protect_from_forgery with: :null_session

  def stash_datacite
    StashDatacite::Engine.routes.url_helpers
  end

end
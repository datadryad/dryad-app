class StashEngine::ApplicationController < ApplicationController

  # this allows csrf to work as part of developer login
  # protect_from_forgery with: :null_session

  def stash_datacite
    StashDatacite::Engine.routes.url_helpers
  end

end
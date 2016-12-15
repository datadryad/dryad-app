Rails.application.routes.draw do
  mount StashDatacite::Engine => "/stash_datacite"
  mount StashEngine::Engine => '/stash_engine'
end

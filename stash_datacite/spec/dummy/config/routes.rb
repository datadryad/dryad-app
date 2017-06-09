Rails.application.routes.draw do
  root requirements: { protocol: 'http' }, to: redirect(path: APP_CONFIG.stash_mount)
  # get "/", to: redirect('/stash')

  get '/help' => 'host_pages#help'
  get '/about' => 'host_pages#about'

  mount StashEngine::Engine, at: APP_CONFIG.stash_mount
  mount StashDatacite::Engine => '/stash_datacite'
end

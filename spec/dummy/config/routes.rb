Rails.application.routes.draw do

  root :to => redirect(path: APP_CONFIG.stash_mount )
  # get "/", to: redirect('/stash')

  get '/help' => 'host_pages#help'
  get '/about' => 'host_pages#about'

  mount StashDatacite::Engine => '/stash_datacite'
  mount StashEngine::Engine => '/stash'

end

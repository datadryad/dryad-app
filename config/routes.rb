StashEngine::Engine.routes.draw do


  resources :resources
  resources :tenants, only: [:index]

  get 'dashboard', to: 'dashboard#show', as: 'dashboard'

  get "login", :to => "test#index"

  match 'auth/:provider/callback', :to => 'test#after_login', :via => [:get, :post]

  get 'test/after_login'

  get 'test/index'

  root 'test#index'

end

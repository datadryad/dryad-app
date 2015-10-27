StashEngine::Engine.routes.draw do

  resources :tenants

  get "login", :to => "test#index"

  match 'auth/:provider/callback', :to => 'test#after_login', :via => [:get, :post]

  get 'test/after_login'

  get 'test/index'

  root 'test#index'
end

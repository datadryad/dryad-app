StashEngine::Engine.routes.draw do

  resources :resources
  resources :tenants, only: [:index, :show]
  resources :file_uploads

  get 'dashboard', to: 'dashboard#show', as: 'dashboard'

  #get "login", :to => "test#index"

  root 'sessions#index'
  match 'auth/:provider/callback', :to => 'sessions#callback', :via => [:get, :post]
  get 'sessions/destroy', :to => 'sessions#destroy'

  #get 'test/after_login'

  #get 'test/index'

end

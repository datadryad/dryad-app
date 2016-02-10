StashEngine::Engine.routes.draw do

  resources :resources do
    member do
      get 'review'
      get 'upload'
    end
  end
  resources :tenants, only: [:index, :show]
  resources :file_uploads

  get 'dashboard', to: 'dashboard#show', as: 'dashboard'

  match 'metadata_entry_pages/find_or_create' => 'metadata_entry_pages#find_or_create', via: [:get, :post, :put]

  # root 'sessions#index'
  root 'pages#home'
  match 'auth/orcid/callback', :to => 'metadata_entry_pages#metadata_callback', :via => [:get, :post]
  match 'auth/:provider/callback', :to => 'sessions#callback', :via => [:get, :post]
  get 'sessions/destroy', :to => 'sessions#destroy'

  get 'about', :to => 'pages#about'
  get 'search', :to => 'searches#index'
  #get "login", :to => "test#index"
  #get 'test/index'
  #get 'test/after_login'
end

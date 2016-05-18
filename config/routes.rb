StashEngine::Engine.routes.draw do

  get 'landing/show'

  resources :resources do
    member do
      get 'review'
      get 'upload'
      get 'submission'
    end
  end
  resources :tenants, only: [:index, :show]
  resources :file_uploads

  get 'dashboard', to: 'dashboard#show', as: 'dashboard'
  get 'get_started', to: 'dashboard#get_started', as: 'get_started'
  get 'metadata_basics', to: 'dashboard#metadata_basics', as: 'metadata_basics'
  get 'preparing_to_submit', to: 'dashboard#preparing_to_submit', as: 'preparing_to_submit'
  get 'upload_basics', to: 'dashboard#upload_basics', as: 'upload_basics'

  match 'metadata_entry_pages/find_or_create' => 'metadata_entry_pages#find_or_create', via: [:get, :post, :put]
  match 'metadata_entry_pages/new_version' => 'metadata_entry_pages#new_version', via: [:post]

  # root 'sessions#index'
  root 'pages#home'
  match 'auth/orcid/callback', :to => 'metadata_entry_pages#metadata_callback', :via => [:get, :post]
  match 'auth/:provider/callback', :to => 'sessions#callback', :via => [:get, :post]
  get 'sessions/destroy', :to => 'sessions#destroy'

  get 'help', :to => 'pages#help'
  get 'about', :to => 'pages#about'
  get 'search', :to => 'searches#index'
  get 'dataset/*id', :to => 'landing#show', as: 'show', :constraints => { :id => /[^ ]+/ }
  #get "login", :to => "test#index"
  #get 'test/index'
  #get 'test/after_login'
end

StashEngine::Engine.routes.draw do

  get 'landing/show'

  resources :resources do
    member do
      get 'review'
      get 'upload'
      get 'submission'
      put 'increment_downloads'
      get 'data_paper'
    end
  end
  resources :tenants, only: [:index, :show]
  resources :file_uploads do
    member do
      patch 'remove'
      patch 'restore'
    end
  end

  resource :file_upload do
    member do
      patch 'revert'
    end
  end

  get 'dashboard/getting_started', to: 'dashboard#getting_started'
  get 'dashboard', to: 'dashboard#show', as: 'dashboard'
  get 'ajax_wait', to: 'dashboard#ajax_wait', as: 'ajax_wait'
  get 'metadata_basics', to: 'dashboard#metadata_basics', as: 'metadata_basics'
  get 'preparing_to_submit', to: 'dashboard#preparing_to_submit', as: 'preparing_to_submit'
  get 'upload_basics', to: 'dashboard#upload_basics', as: 'upload_basics'

  match 'metadata_entry_pages/find_or_create' => 'metadata_entry_pages#find_or_create', via: [:get, :post, :put]
  match 'metadata_entry_pages/new_version' => 'metadata_entry_pages#new_version', via: [:post, :get]

  # root 'sessions#index'
  root 'pages#home'
  match 'auth/orcid/callback', :to => 'metadata_entry_pages#metadata_callback', :via => [:get, :post]
  match 'auth/:provider/callback', :to => 'sessions#callback', :via => [:get, :post]
  get 'auth/failure', :to => redirect('/')
  get 'sessions/destroy', :to => 'sessions#destroy'

  get 'help', :to => 'pages#help'
  get 'about', :to => 'pages#about'
  get 'search', :to => 'searches#index'
  get 'dataset/*id', :to => 'landing#show', as: 'show', :constraints => { :id => /\S+/ }
  get '404', :to => 'pages#app_404', as: 'app_404'

end

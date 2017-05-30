StashEngine::Engine.routes.draw do

  get 'landing/show'

  resources :resources do
    member do
      get 'review'
      get 'upload'
      get 'submission'
      put 'increment_downloads'
      get 'show_files'
    end
  end
  resources :tenants, only: [:index, :show]
  resources :file_uploads do
    member do
      patch 'remove'
      patch 'restore'
      patch 'destroy_error' #destroy an errored file in manifest upload
      patch 'destroy_manifest' #destroy file from manifest method
    end
  end
  match 'file_uploads/validate_urls/:resource_id', to: 'file_uploads#validate_urls', as: 'file_uploads_validate_urls', via: [:get, :post, :put]

  resource :file_upload do  # TODO: this is wacky since it's using a resource id rather than a file id maybe this belongs in resource.
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

  # download related
  match 'downloads/download_resource/:resource_id', to: 'downloads#download_resource', as: 'download_resource', via: [:get, :post]
  match 'downloads/async_request/:resource_id', to: 'downloads#async_request', as: 'download_async_request', via: [:get, :post]
  match 'downloads/capture_email/:resource_id', to: 'downloads#capture_email', as: 'download_capture_email', via: [:get, :post]
  get 'share/:id', to: 'downloads#share', as: 'share'


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
  get 'data_paper/*id', :to => 'landing#data_paper', as: 'data_paper', :constraints => { :id => /\S+/ }
  get '404', :to => 'pages#app_404', as: 'app_404'

  get 'manifests/:id/:filename', to: 'manifests#show'
  patch 'dataset/*id', :to => 'landing#update', :constraints => { :id => /\S+/ }

  get 'embargoes/new', to: 'embargoes#new'
  post 'embargoes/create', to: 'embargoes#create'
  patch 'embargoes/update', to: 'embargoes#update'
  delete 'embargoes/:id/delete', to: 'embargoes#delete'
  post 'embargoes/:resource_id/changed/', to: 'embargoes#changed', as: 'embargoes_changed'

  post 'shares/create', to: 'shares#create'
  patch 'shares/update', to: 'shares#update'
  delete 'shares/:id/delete', to: 'shares#delete'

end

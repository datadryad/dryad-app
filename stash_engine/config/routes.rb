StashEngine::Engine.routes.draw do

  get 'landing/show'

  resources :resources do
    member do
      get 'review'
      get 'upload'
      get 'upload_manifest'
      get 'submission'
      get 'show_files'
    end
    resources :internal_data
    # TODO: curation_activity is a bit weird because it nests inside the resource in the routes but it is really related to
    # stash_engine_identifiers, not stash_engine_resources
    resources :curation_activity
  end
  post 'curation_status_change/:id', to: 'curation_activity#status_change', as: 'curation_status_change'
  resources :tenants, only: [:index, :show]
  resources :file_uploads do
    member do
      patch 'remove'
      patch 'remove_unuploaded'
      patch 'restore'
      patch 'destroy_error' #destroy an errored file in manifest upload
      patch 'destroy_manifest' #destroy file from manifest method
    end
  end

  resources :edit_histories, only: [:index]
  match 'file_uploads/validate_urls/:resource_id', to: 'file_uploads#validate_urls', as: 'file_uploads_validate_urls', via: [:get, :post, :put]

  resource :file_upload do  # TODO: this is wacky since it's using a resource id rather than a file id maybe this belongs in resource.
    member do
      patch 'revert'
    end
  end

  get 'dashboard', to: 'dashboard#show', as: 'dashboard'
  get 'ajax_wait', to: 'dashboard#ajax_wait', as: 'ajax_wait'
  get 'metadata_basics', to: 'dashboard#metadata_basics', as: 'metadata_basics'
  get 'preparing_to_submit', to: 'dashboard#preparing_to_submit', as: 'preparing_to_submit'
  get 'upload_basics', to: 'dashboard#upload_basics', as: 'upload_basics'

  # download related
  match 'downloads/download_resource/:resource_id', to: 'downloads#download_resource', as: 'download_resource', via: [:get, :post]
  match 'downloads/async_request/:resource_id', to: 'downloads#async_request', as: 'download_async_request', via: [:get, :post]
  match 'downloads/capture_email/:resource_id', to: 'downloads#capture_email', as: 'download_capture_email', via: [:get, :post]
  get 'downloads/file_stream/:file_id', to: 'downloads#file_stream', as: 'download_file_stream'
  get 'downloads/file_download/:file_id', to: 'downloads#file_download', as: 'download_file'
  get 'share/:id', to: 'downloads#share', as: 'share'


  match 'metadata_entry_pages/find_or_create', to: 'metadata_entry_pages#find_or_create', via: [:get, :post, :put]
  match 'metadata_entry_pages/new_version', to: 'metadata_entry_pages#new_version', via: [:post, :get]
  match 'metadata_entry_pages/reject_agreement', to: 'metadata_entry_pages#reject_agreement', via: [:delete]
  match 'metadata_entry_pages/accept_agreement', to: 'metadata_entry_pages#accept_agreement', via: [:post]

  # root 'sessions#index'
  root 'pages#home'

  match 'auth/orcid/callback', to: 'sessions#orcid_callback', via: [:get, :post]
  match 'auth/developer/callback', to: 'sessions#developer_callback', via: [:get, :post]
  match 'auth/:provider/callback', to: 'sessions#callback', via: [:get, :post]
  match 'auth/migrate/mail',  to: 'dashboard#migrate_data_mail', via: [:get]
  match 'auth/migrate/code', to: 'dashboard#migrate_data', via: [:get]
  match 'auth/migrate/done', to: 'dashboard#migration_complete', via: [:get]

  match 'terms/view', :to => 'dashboard#view_terms', :via => [:get, :post]
  match 'terms/accept', :to => 'dashboard#accept_terms', :via => [:get, :post]

  get 'auth/failure', to: redirect('/')
  match 'sessions/destroy', to: 'sessions#destroy', :via => [:get, :post]
  get 'sessions/choose_login', to: 'sessions#choose_login', as: 'choose_login'
  get 'sessions/choose_sso', to: 'sessions#choose_sso', as: 'choose_sso'
  post 'sessions/no_partner', to: 'sessions#no_partner', as: 'no_partner'

  get 'help', to: 'pages#help'
  get 'faq', to: 'pages#faq'
  get 'about', to: 'pages#about'
  get 'dda', to: 'pages#dda' #data deposit agreement
  get 'search', to: 'searches#index'
  get 'editor', to: 'pages#editor'
  get 'dataset/*id', to: 'landing#show', as: 'show', constraints: { id: /\S+/ }
  get 'data_paper/*id', to: 'landing#data_paper', as: 'data_paper', constraints: { id: /\S+/ }
  get 'landing/citations/:identifier_id', to: 'landing#citations', as: 'show_citations'
  get '404', to: 'pages#app_404', as: 'app_404'

  patch 'dataset/*id', to: 'landing#update', constraints: { id: /\S+/ }

  get 'embargoes/new', to: 'embargoes#new'
  post 'embargoes/create', to: 'embargoes#create'
  patch 'embargoes/update', to: 'embargoes#update'
  delete 'embargoes/:id/delete', to: 'embargoes#delete'
  post 'embargoes/:resource_id/changed/', to: 'embargoes#changed', as: 'embargoes_changed'

  post 'shares/create', to: 'shares#create'
  patch 'shares/update', to: 'shares#update'
  delete 'shares/:id/delete', to: 'shares#delete'

  # admin area
  get 'admin', to: 'admin#index'
  get 'admin/popup/:id', to: 'admin#popup', as: 'popup_admin'
  post 'admin/set_role/:id', to: 'admin#set_role', as: 'admin_set_role'
  get 'admin/user_dashboard/:id', to: 'admin#user_dashboard', as: 'admin_user_dashboard'

  # admin_datasets, this routes actions to ds_admin with a possible id without having to define for each get action, default is index
  get 'ds_admin/(:action(/:id))', to: 'admin_datasets'

end

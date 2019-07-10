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
    # TODO: curation_activity is a bit weird because it nests inside the resource in the routes but it is really related to
    # stash_engine_identifiers, not stash_engine_resources
    # resources :curation_activity
  end

  resources :identifiers do
    resources :internal_data, shallow: true
  end

  post 'curation_note/:id', to: 'curation_activity#curation_note', as: 'curation_note'
  post 'curation_activity_change/:id', to: 'admin_datasets#curation_activity_change', as: 'curation_activity_change'
  resources :tenants, only: %i[index show]
  resources :file_uploads do
    member do
      patch 'remove'
      patch 'remove_unuploaded'
      patch 'restore'
      patch 'destroy_error' # destroy an errored file in manifest upload
      patch 'destroy_manifest' # destroy file from manifest method
    end
  end

  resources :edit_histories, only: [:index]
  match 'file_uploads/validate_urls/:resource_id', to: 'file_uploads#validate_urls', as: 'file_uploads_validate_urls', via: %i[get post put]

  resource :file_upload do # TODO: this is wacky since it's using a resource id rather than a file id maybe this belongs in resource.
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
  match 'downloads/download_resource/:resource_id', to: 'downloads#download_resource', as: 'download_resource', via: %i[get post]
  match 'downloads/async_request/:resource_id', to: 'downloads#async_request', as: 'download_async_request', via: %i[get post]
  get 'downloads/private_async_form', to: 'downloads#private_async_form', as: 'private_async_form'
  match 'downloads/capture_email/:resource_id', to: 'downloads#capture_email', as: 'download_capture_email', via: %i[get post]
  get 'downloads/file_stream/:file_id', to: 'downloads#file_stream', as: 'download_stream'
  get 'share/:id', to: 'downloads#share', as: 'share'

  match 'metadata_entry_pages/find_or_create', to: 'metadata_entry_pages#find_or_create', via: %i[get post put]
  match 'metadata_entry_pages/new_version', to: 'metadata_entry_pages#new_version', via: %i[post get]
  match 'metadata_entry_pages/reject_agreement', to: 'metadata_entry_pages#reject_agreement', via: [:delete]
  match 'metadata_entry_pages/accept_agreement', to: 'metadata_entry_pages#accept_agreement', via: [:post]

  # root 'sessions#index'
  root 'pages#home'

  match 'auth/orcid/callback', to: 'sessions#orcid_callback', via: %i[get post]
  match 'auth/developer/callback', to: 'sessions#developer_callback', via: %i[get post]
  match 'auth/:provider/callback', to: 'sessions#callback', via: %i[get post]
  match 'auth/migrate/mail', to: 'dashboard#migrate_data_mail', via: [:get]
  match 'auth/migrate/code', to: 'dashboard#migrate_data', via: [:get]
  match 'auth/migrate/done', to: 'dashboard#migration_complete', via: [:get]

  match 'terms/view', to: 'dashboard#view_terms', via: %i[get post]

  get 'auth/failure', to: redirect('/')
  match 'sessions/destroy', to: 'sessions#destroy', via: %i[get post]
  get 'sessions/choose_login', to: 'sessions#choose_login', as: 'choose_login'
  get 'sessions/choose_sso', to: 'sessions#choose_sso', as: 'choose_sso'
  post 'sessions/no_partner', to: 'sessions#no_partner', as: 'no_partner'
  post 'sessions/sso', to: 'sessions#sso', as: 'sso'

  get 'help', to: 'pages#help'
  get 'faq', to: 'pages#faq'
  get 'about', to: 'pages#about'
  get 'dda', to: 'pages#dda' # data deposit agreement
  get 'search', to: 'searches#index'
  get 'editor', to: 'pages#editor'
  get 'dataset/*id', to: 'landing#show', as: 'show', constraints: { id: /\S+/ }
  get 'data_paper/*id', to: 'landing#data_paper', as: 'data_paper', constraints: { id: /\S+/ }
  get 'landing/citations/:identifier_id', to: 'landing#citations', as: 'show_citations'
  get '404', to: 'pages#app_404', as: 'app_404'
  get 'landing/metrics/:identifier_id', to: 'landing#metrics', as: 'show_metrics'

  patch 'dataset/*id', to: 'landing#update', constraints: { id: /\S+/ }

  post 'shares/create', to: 'shares#create'
  patch 'shares/update', to: 'shares#update'
  delete 'shares/:id/delete', to: 'shares#delete'

  # admin area
  get 'admin', to: 'admin#index'
  get 'admin/popup/:id', to: 'admin#popup', as: 'popup_admin'
  post 'admin/set_role/:id', to: 'admin#set_role', as: 'admin_set_role'
  get 'admin/user_dashboard/:id', to: 'admin#user_dashboard', as: 'admin_user_dashboard'

  # admin_datasets, this routes actions to ds_admin with a possible id without having to define for each get action, default is index
  get 'ds_admin/(:action(/:id))', controller: 'admin_datasets'

  # flexible routing for submission queue controller
  get 'submission_queue/(:action(/:id))', controller: 'submission_queue'

  # Administrative Status Dashboard that displays statuses of external dependencies
  get 'status_dashboard', to: 'status_dashboard#show'

  # Publication updater page - Allows admins to accept/reject metadata changes from external sources like Crrossref
  get 'publication_updater', to: 'publication_updater#index'
  put 'publication_updater/:id', to: 'publication_updater#update'
  delete 'publication_updater/:id', to: 'publication_updater#destroy'
end

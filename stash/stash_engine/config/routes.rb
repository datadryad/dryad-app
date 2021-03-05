# rubocop:disable Metrics/BlockLength
StashEngine::Engine.routes.draw do

  get 'landing/show'

  resources :resources do
    member do
      get 'review'
      get 'upload'
      get 'upload_manifest'
      get 'up_code'
      get 'up_code_manifest'
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
  resources :file_uploads, :software_uploads do
    member do
      patch 'remove'
      patch 'remove_unuploaded'
      patch 'restore'
      patch 'destroy_error' # destroy an errored file in manifest upload
      patch 'destroy_manifest' # destroy file from manifest method
    end
  end



  resources :edit_histories, only: [:index]

  # these are weird and different and want to get rid of these when we move to only one model for all kinds of uploads
  match 'file_upload/validate_urls/:resource_id', to: 'file_uploads#validate_urls', as: 'file_upload_validate_urls', via: %i[get post put]
  match 'software_upload/validate_urls/:resource_id', to: 'software_uploads#validate_urls', as: 'software_upload_validate_urls', via: %i[get post put]

  get 'file_upload/presign_upload/:resource_id', to: 'file_uploads#presign_upload', as: 'file_upload_presign_url'
  get 'software_upload/presign_upload/:resource_id', to: 'software_uploads#presign_upload', as: 'software_upload_presign_url'

  post 'file_upload/upload_complete/:resource_id', to: 'file_uploads#upload_complete', as: 'file_upload_complete'
  post 'software_upload/upload_complete/:resource_id', to: 'software_uploads#upload_complete', as: 'software_upload_complete'



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
  match 'downloads/capture_email/:resource_id', to: 'downloads#capture_email', as: 'download_capture_email', via: %i[get post]
  get 'downloads/file_stream/:file_id', to: 'downloads#file_stream', as: 'download_stream'
  get 'downloads/zenodo_file/:file_id', to: 'downloads#zenodo_file', as: 'download_zenodo'
  get 'share/:id', to: 'downloads#share', as: 'share'
  get 'downloads/assembly_status/:id', to: 'downloads#assembly_status', as: 'download_assembly_status'

  get 'edit/:doi/:edit_code', to: 'metadata_entry_pages#edit_by_doi', as: 'edit', constraints: { doi: /\S+/ }
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
  match 'session/test_login', to: 'sessions#test_login', via: [:get, :post],  as: 'test_login'

  match 'terms/view', to: 'dashboard#view_terms', via: %i[get post]

  get 'auth/failure', to: redirect('/')
  match 'sessions/destroy', to: 'sessions#destroy', via: %i[get post]
  get 'sessions/choose_login', to: 'sessions#choose_login', as: 'choose_login'
  get 'sessions/choose_sso', to: 'sessions#choose_sso', as: 'choose_sso'
  post 'sessions/no_partner', to: 'sessions#no_partner', as: 'no_partner'
  post 'sessions/sso', to: 'sessions#sso', as: 'sso'

  get 'faq', to: 'pages#faq'
  get 'best_practices', to: 'pages#best_practices'
  get 'our_community', to: 'pages#our_community'
  get 'our_governance', to: 'pages#our_governance'
  get 'our_mission', to: 'pages#our_mission'
  get 'our_platform', to: 'pages#our_platform'
  get 'our_staff', to: 'pages#our_staff'
  get 'our_advisors', to: 'pages#our_advisors'
  get 'submission_process', to: 'pages#submission_process'
  get 'why_use', to: 'pages#why_use'
  get 'dda', to: 'pages#dda' # data deposit agreement
  get 'search', to: 'searches#index'
  get 'terms', to: 'pages#terms'
  get 'editor', to: 'pages#editor'
  get 'dataset/*id', to: 'landing#show', as: 'show', constraints: { id: /\S+/ }
  get 'landing/citations/:identifier_id', to: 'landing#citations', as: 'show_citations'
  get '404', to: 'pages#app_404', as: 'app_404'
  get 'landing/metrics/:identifier_id', to: 'landing#metrics', as: 'show_metrics'

  patch 'dataset/*id', to: 'landing#update', constraints: { id: /\S+/ }

  # admin area
  get 'admin', to: 'admin#index'
  get 'admin/popup/:id', to: 'admin#popup', as: 'popup_admin'
  post 'admin/set_role/:id', to: 'admin#set_role', as: 'admin_set_role'
  get 'admin/user_dashboard/:id', to: 'admin#user_dashboard', as: 'admin_user_dashboard'

  # admin_datasets, this routes actions to ds_admin with a possible id without having to define for each get action, default is index
  get 'ds_admin', to: 'admin_datasets#index'
  get 'ds_admin/index', to: 'admin_datasets#index'
  get 'ds_admin/index/:id', to: 'admin_datasets#index'
  get 'ds_admin/data_popup/:id', to: 'admin_datasets#data_popup'
  get 'ds_admin/note_popup/:id', to: 'admin_datasets#note_popup'
  get 'ds_admin/curation_activity_popup/:id', to: 'admin_datasets#curation_activity_popup'
  get 'ds_admin/curation_activity_change/:id', to: 'admin_datasets#curation_activity_change'
  get 'ds_admin/activity_log/:id', to: 'admin_datasets#activity_log'
  get 'ds_admin/stats_popup/:id', to: 'admin_datasets#stats_popup'

  # routing for submission queue controller
  get 'submission_queue', to: 'submission_queue#index'
  get 'submission_queue/refresh_table', to: 'submission_queue#refresh_table'
  get 'submission_queue/graceful_shutdown', to: 'submission_queue#graceful_shutdown'
  get 'submission_queue/graceful_start', to: 'submission_queue#graceful_start'
  get 'submission_queue/ungraceful_start', to: 'submission_queue#ungraceful_start'

  # Administrative Status Dashboard that displays statuses of external dependencies
  get 'status_dashboard', to: 'status_dashboard#show'

  # Publication updater page - Allows admins to accept/reject metadata changes from external sources like Crrossref
  get 'publication_updater', to: 'publication_updater#index'
  put 'publication_updater/:id', to: 'publication_updater#update'
  delete 'publication_updater/:id', to: 'publication_updater#destroy'
end
# rubocop:enable Metrics/BlockLength

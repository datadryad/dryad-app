Rails.application.routes.draw do
  match '(*any)', to: redirect(subdomain: ''), via: :all, constraints: {subdomain: 'www'}
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  use_doorkeeper
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rails routes".

  root :requirements => { :protocol => 'http' }, :to => redirect(path: APP_CONFIG.stash_mount )

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.local? || Rails.env.v3_development?

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # this is a rack way of showing a 404 for some crazy old/speculative link that Google has stuck in its craw
  get '/search/facet/dc_creator_sm', to: proc { [410, {}, ['']] }

  get 'xtf/search', :to => redirect { |params, request| "/search?#{request.params.to_query}" }

  # This will route an item at the root of the site into the namespaced engine.
  # However it is currently broken, so commented out until we fix it.
  get 'sitemap.xml' => "stash_engine/pages#sitemap", :format => "xml", :as => 'sitemap'

  # routing this into the engine since that is where we have all our models and curation state info which we need
  get 'widgets/bannerForPub' => 'stash_engine/widgets#banner_for_pub'
  get 'widgets/dataPackageForPub' => 'stash_engine/widgets#data_package_for_pub'

  # react test
  get 'react' => 'react_test#index'

  # Individual pages that we're redirecting from the old wiki, then a catchall
  # for any other page from the old wiki. The individual pages must be listed
  # first, or they will not take effect.
  get '/Governance', to: redirect('stash/our_governance')
  get '*path',
      constraints: {host: 'wiki.datadryad.org'},
      to: redirect('https://github.com/datadryad/dryad-app/tree/main/documentation/v1_wiki_content.md')

  ############################# API support ######################################

  scope module: 'stash_api', path: '/api/v2' do
    # StashApi::GeneralController#index
    get '/', to: 'api#index'
    match '/test', to: 'api#test', via: %i[get post]
    match '/search', to: 'datasets#search', via: %i[get]
    get '/reports', to: 'api#reports_index'
    get '/reports(/:report_name)', to: 'api#reports'

    # Support for the Editorial Manager API
    match '/em_submission_metadata(/:id)', constraints: { id: /\S+/ }, to: 'datasets#em_submission_metadata', via: %i[post put]

    resources :datasets, shallow: true, id: %r{[^\s/]+?}, format: /json|xml|yaml/, path: '/datasets' do
      member do
        get 'download'
        post 'set_internal_datum'
        post 'add_internal_datum'
      end
      resources :related_works, shallow: false, only: 'update'
      resources :internal_data, shallow: true, path: '/internal_data'
      resources :curation_activity, shallow: false, path: '/curation_activity'

      resources :versions, shallow: true, path: '/versions' do
        get 'download', on: :member
        get 'zip_assembly(/:token)', token: %r{[^\s/]+?}, to: 'versions#zip_assembly', as: 'zip_assembly'
        resources :files, shallow: true, path: '/files' do
          get :download, on: :member
          resource :frictionless_report, path: '/frictionlessReport'
        end
        resources :processor_results, only: [:show, :index, :create, :update]
      end

      resources :urls, shallow: true, path: '/urls', only: [:create]
    end

    # this one doesn't follow the pattern since it gloms filename on the end, so manual route
    # supporting both POST and PUT for updating the file to ensure as many clients as possible can use this end point
    match '/datasets/:id/files/:filename', to: 'files#update', as: 'dataset_file', constraints: { id: %r{[^\s/]+?}, filename: %r{[^\s/]+?} }, format: false, via: %i[post put]

    resources :users, path: '/users', only: %i[index show]

    get '/queue_length', to: 'submission_queue#length'
  end

  ############################# Discovery support ######################################

  get '/latest', to: 'latest#index', as: 'latest_index'
  # blacklight_for :catalog

  # Endpoint for LinkOut
  get :discover, to: 'catalog#discover'

  ########################## StashEngine support ######################################

  scope module: 'stash_engine', path: '/stash' do

    get 'landing/show'

    resources :resources do
      member do
        get 'prepare_readme'
        get 'display_readme'
        get 'dpc_status'
        get 'dupe_check'
        get 'display_collection'
        get 'show_files'
        patch 'import_type'
      end
    end

    resources :identifiers do
      resources :internal_data, shallow: true, as: 'identifier_internal_data'
    end
    match 'identifier_internal_data/:identifier_id', to: 'internal_data#create', as: 'internal_data_create', via: %i[get post put]
    resources :internal_data, shallow: true, as: 'stash_engine_internal_data'
    resources :resource_publications, shallow: true, as: 'resource_publication'

    resources :tenants, only: %i[index show]
    resources :data_files, :software_files, :supp_files do
      member do
        patch 'destroy_manifest' # destroy file from manifest method
      end
    end

    resources :edit_histories, only: [:index]

    # these are weird and different and want to get rid of these with file redesign
    match 'data_file/validate_urls/:resource_id', to: 'data_files#validate_urls', as: 'data_file_validate_urls', via: %i[get post put]
    match 'software_file/validate_urls/:resource_id', to: 'software_files#validate_urls', as: 'software_file_validate_urls', via: %i[get post put]
    match 'supp_file/validate_urls/:resource_id', to: 'supp_files#validate_urls', as: 'supp_file_validate_urls', via: %i[get post put]

    get 'data_file/presign_upload/:resource_id', to: 'data_files#presign_upload', as: 'data_file_presign_url'
    get 'software_file/presign_upload/:resource_id', to: 'software_files#presign_upload', as: 'software_file_presign_url'
    get 'supp_file/presign_upload/:resource_id', to: 'supp_files#presign_upload', as: 'supp_file_presign_url'
    # TODO: this is to be the replacement for the 3 above
    get 'generic_file/presign_upload/:resource_id', to: 'generic_files#presign_upload', as: 'generic_file_presign_url'

    post 'data_file/upload_complete/:resource_id', to: 'data_files#upload_complete', as: 'data_file_complete'
    post 'software_file/upload_complete/:resource_id', to: 'software_files#upload_complete', as: 'software_file_complete'
    post 'supp_file/upload_complete/:resource_id', to: 'supp_files#upload_complete', as: 'supp_file_complete'

    post 'generic_file/trigger_frictionless/:resource_id',
         to: 'generic_files#trigger_frictionless',
         as: 'generic_file_trigger_frictionless'

    get 'generic_file/check_frictionless/:resource_id',
        to: 'generic_files#check_frictionless',
        as: 'generic_file_check_frictionless'

    get 'choose_dashboard', to: 'dashboard#choose', as: 'choose_dashboard'
    get 'dashboard', to: 'dashboard#show', as: 'dashboard'
    get 'dashboard/user_datasets', to: 'dashboard#user_datasets'
    get 'ajax_wait', to: 'dashboard#ajax_wait', as: 'ajax_wait'
    get 'metadata_basics', to: 'dashboard#metadata_basics', as: 'metadata_basics'
    get 'preparing_to_submit', to: 'dashboard#preparing_to_submit', as: 'preparing_to_submit'
    get 'upload_basics', to: 'dashboard#upload_basics', as: 'upload_basics'
    get 'react_basics', to: 'dashboard#react_basics', as: 'react_basics'

    # download related
    match 'downloads/zip_assembly_info/:resource_id', to: 'downloads#zip_assembly_info', as: 'zip_assembly_info', via: %i[get post]
    match 'downloads/download_resource/:resource_id', to: 'downloads#download_resource', as: 'download_resource', via: %i[get post]
    match 'downloads/capture_email/:resource_id', to: 'downloads#capture_email', as: 'download_capture_email', via: %i[get post]
    get 'downloads/file_stream/:file_id', to: 'downloads#file_stream', as: 'download_stream'
    get 'downloads/zenodo_file/:file_id', to: 'downloads#zenodo_file', as: 'download_zenodo'
    get 'data_file/preview_check/:file_id', to: 'downloads#preview_check', as: 'preview_check'
    get 'data_file/preview/:file_id', to: 'downloads#preview_file', as: 'preview_file'
    get 'share/:id', to: 'downloads#share', as: 'share'
    get 'downloads/assembly_status/:id', to: 'downloads#assembly_status', as: 'download_assembly_status'

    get 'edit/:doi/:edit_code', to: 'metadata_entry_pages#edit_by_doi', as: 'edit', constraints: { doi: /\S+/ }
    match 'metadata_entry_pages/find_or_create', to: 'metadata_entry_pages#find_or_create', via: %i[get post put]
    match 'metadata_entry_pages/new_version', to: 'metadata_entry_pages#new_version', via: %i[post get]
    post 'metadata_entry_pages/new_version_from_previous', to: 'metadata_entry_pages#new_version_from_previous'
    match 'metadata_entry_pages/reject_agreement', to: 'metadata_entry_pages#reject_agreement', via: [:post]
    match 'metadata_entry_pages/accept_agreement', to: 'metadata_entry_pages#accept_agreement', via: [:post]

    # root 'sessions#index'
    root 'pages#home', as: 'pages_root'

    match 'auth/orcid/callback', to: 'sessions#orcid_callback', via: %i[get post]
    match 'auth/google_oauth2/callback', to: 'sessions#google_callback', via: %i[get post]
    match 'auth/developer/callback', to: 'sessions#developer_callback', via: %i[get post]
    match 'auth/:provider/callback', to: 'sessions#callback', via: %i[get post]
    match 'session/test_login', to: 'sessions#test_login', via: [:get, :post],  as: 'test_login'

    match 'terms/view', to: 'dashboard#view_terms', via: %i[get post]

    get 'auth/failure', to: redirect('/')
    match 'sessions/destroy', to: 'sessions#destroy', via: %i[get post]
    get 'sessions/choose_login', to: 'sessions#choose_login', as: 'choose_login'
    get 'sessions/choose_sso', to: 'sessions#choose_sso', as: 'choose_sso'
    match 'sessions/no_partner', to: 'sessions#no_partner', as: 'no_partner', via: [:get, :post]
    post 'sessions/sso', to: 'sessions#sso', as: 'sso'
    get 'feedback', to: 'sessions#feedback', as: 'feedback'
    post 'feedback_signup', to: 'sessions#feedback_signup', as: 'feedback_signup'

    get 'close_page', to: 'pages#close_page'
    get 'requirements', to: 'pages#requirements'
    get 'contact', to: 'pages#contact'
    get 'best_practices', to: 'pages#best_practices'
    get 'mission', to: 'pages#what_we_do'
    get 'contact_thanks', to: 'pages#contact_thanks'
    get 'join_us', to: 'pages#join_us'
    get 'code_of_conduct', to: 'pages#code_of_conduct'
    get 'ethics', to: 'pages#ethics'
    get 'pb_tombstone', to: 'pages#pb_tombstone'
    get 'submission_process', to: 'pages#submission_process'
    get 'data_check_guide', to: 'pages#data_check_guide'
    get 'process', to: 'pages#process'
    get 'why_use', to: 'pages#why_use'
    get 'dda', to: 'pages#dda' # data deposit agreement
    get 'search', to: 'searches#index'
    get 'terms', to: 'pages#terms'
    get 'editor', to: 'pages#editor'
    get 'web_crawling', to: 'pages#web_crawling'
    get 'about', to: 'pages#who_we_are'
    get 'api', to: 'pages#api'
    get 'definitions', to: 'pages#definitions'
    get 'publication_policy', to: 'pages#publication_policy'
    get 'privacy', to: 'pages#privacy'
    get 'accessibility', to: 'pages#accessibility'
    get 'membership', to: 'pages#membership'

    # redirect the urls with an encoded forward slash in the identifier to a URL that DataCite expects for matching their tracker
    # All our identifiers seem to have either /dryad or /FK2 or /[A-Z]\d in them, replaces the first occurrence of %2F with /
    get 'dataset/*id', to: redirect{ |params| "/stash/dataset/#{params[:id].sub('%2F', '/') }"}, status: 302,
        constraints: { id: /\S+\d%2F(dryad|FK2|[A-Z]\d)\S+/ }
    get 'dataset/*id', to: 'landing#show', as: 'show', constraints: { id: /\S+/ }
    get 'landing/citations/:identifier_id', to: 'landing#citations', as: 'show_citations'
    get '404', to: 'pages#app_404', as: 'app_404'
    get 'landing/metrics/:identifier_id', to: 'landing#metrics', as: 'show_metrics'
    get 'test', to: 'pages#test'
    get 'ip_error', to: 'pages#ip_error'

    # user management
    get 'account', to: 'user_account#index', as: 'my_account'
    post 'account/edit', to: 'user_account#edit', as: 'edit_account'
    # admin user management
    get 'user_admin', to: 'user_admin#index' # main page for administering users
    # page for viewing a single user
    get 'user_admin/user_profile/:id', to: 'user_admin#user_profile', as: 'user_admin_profile'
    post 'user_admin/set_role/:id', to: 'user_admin#set_role', as: 'user_admin_set_role'
    # admin editing user
    get 'user_admin/merge', to: 'user_admin#merge_popup', as: 'user_merge_popup'
    post 'user_admin/merge', to: 'user_admin#merge', as: 'user_admin_merge'
    get 'user_admin/:id/edit/:field', to: 'user_admin#popup', as: 'user_popup'
    post 'user_admin/:id', to: 'user_admin#edit', as: 'user_admin_edit'
    # admin tenant management
    get 'tenant_admin', to: 'tenant_admin#index'
    get 'tenant_admin/:id/edit/:field', to: 'tenant_admin#popup', as: 'tenant_popup'
    post 'tenant_admin/:id', to: 'tenant_admin#edit', as: 'tenant_edit'
    # admin journal management
    get 'journal_admin', to: 'journal_admin#index'
    get 'journal_admin/:id/edit/:field', to: 'journal_admin#popup', as: 'journal_popup'
    post 'journal_admin/:id', to: 'journal_admin#edit', as: 'journal_edit'
    # admin publisher management
    get 'publisher_admin', to: 'journal_organization_admin#index', as: 'publisher_admin'
    get 'publisher_admin/:id/edit/:field', to: 'journal_organization_admin#popup', as: 'publisher_popup'
    post 'publisher_admin/:id', to: 'journal_organization_admin#edit', as: 'publisher_edit'

    # admin_dashboard
    match 'admin_dashboard', to: 'admin_dashboard#index', via: %i[get post]
    match 'admin_dashboard/results', to: 'admin_dashboard#results', via: %i[get post], as: 'admin_dashboard_results'
    match 'admin_dashboard/count', to: 'admin_dashboard#count', via: %i[get post], as: 'admin_dashboard_count'
    get 'admin_dashboard/:id/edit/:field', to: 'admin_dashboard#edit', as: 'admin_dash_edit'
    post 'admin_dashboard/:id', to: 'admin_dashboard#update', as: 'admin_dash_update'
    get 'admin_search', to: 'admin_dashboard#new_search', as: 'new_admin_search'
    match 'admin_search/:id', to: 'admin_dashboard#save_search', via: %i[put patch], as: 'save_admin_search'

    # saved_searches
    # get 'account/saved_searches/:type', to: 'saved_searches#index'
    post 'saved_search', to: 'saved_searches#create'
    get 'saved_search/:id', to: 'saved_searches#edit', as: 'saved_search_edit'
    match 'saved_search/:id', to: 'saved_searches#update', via: %i[put patch], as: 'update_saved_search'
    delete 'saved_search/:id', to: 'saved_searches#destroy', as: 'saved_search_delete'

    # activity log
    get 'ds_admin/:id/create_salesforce_case', to: 'admin_datasets#create_salesforce_case', as: 'create_salesforce_case'
    get 'ds_admin/:id/activity_log', to: 'admin_datasets#activity_log', as: 'activity_log'
    get 'ds_admin/:id/edit/:field', to: 'admin_datasets#popup', as: 'ds_admin_popup'
    post 'ds_admin/:id', to: 'admin_datasets#edit', as: 'ds_admin_edit'

    # curation notes
    post 'curation_note/:id', to: 'curation_activity#curation_note', as: 'curation_note'
    post 'file_note/:id', to: 'curation_activity#file_note', as: 'file_note'

    # admin report for dataset funders
    get 'ds_admin_funders', to: 'admin_dataset_funders#index', as: 'ds_admin_funders'

    # routing for submission queue controller
    get 'submission_queue', to: 'submission_queue#index'
    get 'submission_queue/refresh_table', to: 'submission_queue#refresh_table'
    get 'submission_queue/graceful_start', to: 'submission_queue#graceful_start', as: 'graceful_start'

    # routing for zenodo_queue
    get 'zenodo_queue', to: 'zenodo_queue#index', as: 'zenodo_queue'
    get 'zenodo_queue/item_details/:id', to: 'zenodo_queue#item_details', as: 'zenodo_queue_item_details'
    get 'zenodo_queue/identifier_details/:id', to: 'zenodo_queue#identifier_details', as: 'zenodo_queue_identifier_details'
    post 'zenodo_queue/resubmit_job', to: 'zenodo_queue#resubmit_job', as: 'zenodo_queue_resubmit_job'
    post 'zenodo_queue/set_errored', to: 'zenodo_queue#set_errored', as: 'zenodo_queue_set_errored'

    # Administrative Status Dashboard that displays statuses of external dependencies
    get 'status_dashboard', to: 'status_dashboard#show'

    # Publication updater page - Allows admins to accept/reject metadata changes from external sources like Crrossref
    get 'publication_updater', to: 'publication_updater#index'
    put 'publication_updater/:id', to: 'publication_updater#update'
    delete 'publication_updater/:id', to: 'publication_updater#destroy'

    # Curation stats
    get 'curation_stats', to: 'curation_stats#index'

    # Journals
    get 'journals', to: 'journals#index'

    # GMail authentication page for journals
    get 'gmail_auth', to: 'gmail_auth#index'

    resource :pots, only: [:show]
  end

  # the ones below coming from new routing for blacklight
  #--------------------------------------------------------
  mount Blacklight::Engine => '/'

  get '/search', to: 'catalog#index'

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/search', controller: 'catalog' do
    concerns :searchable
  end

  # this is kind of hacky, but it directs our search results to open links to the landing pages
  resources :solr_documents, only: [:show], path: '/stash/dataset', controller: 'catalog'

  ########################## StashDatacite support ######################################

  scope module: 'stash_datacite', path: '/stash_datacite' do
    get 'titles/new', to: 'titles#new'
    post 'titles/create', to: 'titles#create'
    patch 'titles/update', to: 'titles#update'

    get 'descriptions/new', to: 'descriptions#new'
    patch 'descriptions/update', to: 'descriptions#update'

    get 'temporal_coverages/new', to: 'temporal_coverages#new'
    patch 'temporal_coverages/update', to: 'temporal_coverages#update'

    get 'authors/new', to: 'authors#new'
    post 'authors/create', to: 'authors#create'
    patch 'authors/update', to: 'authors#update'
    delete 'authors/:id/delete', to: 'authors#delete', as: 'authors_delete'
    patch 'authors/reorder', to: 'authors#reorder', as: 'authors_reorder'

    get 'contributors/new', to: 'contributors#new'
    get 'contributors/autocomplete', to: 'contributors#autocomplete'
    get 'contributors/groupings', to: 'contributors#groupings'
    post 'contributors/create', to: 'contributors#create'
    patch 'contributors/update', to: 'contributors#update'
    patch 'contributors/reorder', to: 'contributors#reorder', as: 'contributors_reorder'
    delete 'contributors/:id/delete', to: 'contributors#delete', as: 'contributors_delete'

    get 'publications/new', to: 'publications#new'
    get 'publications/autocomplete', to: 'publications#autocomplete'
    get 'publications/api_list', to: 'publications#api_list'
    get 'publications/issn/:id', to: 'publications#issn'
    post 'publications/create', to: 'publications#create'
    patch 'publications/update', to: 'publications#update'
    delete 'publications/:id/delete', to: 'publications#delete', as: 'publications_delete'
    post 'publications/autofill/:id', to: 'publications#autofill_data', as: 'publications_autofill_data'

    get 'resource_types/new', to: 'resource_types#new'
    post 'resource_types/create', to: 'resource_types#create'
    patch 'resource_types/update', to: 'resource_types#update'

    get 'subjects/new', to: 'subjects#new'
    get 'subjects/autocomplete', to: 'subjects#autocomplete'
    post 'subjects/create', to: 'subjects#create'
    delete 'subjects/:id/delete', to: 'subjects#delete', as: 'subjects_delete'
    get 'subjects/landing', to: 'subjects#landing', as: 'subjects_landing'

    # fos subjects are a special subject that is treated differently for the OECD Field of Science
    get 'fos_subjects', to: 'fos_subjects#index'
    patch 'fos_subjects/update', to: 'fos_subjects#update'

    get 'related_identifiers/new', to: 'related_identifiers#new'
    post 'related_identifiers/create', to: 'related_identifiers#create'
    patch 'related_identifiers/update', to: 'related_identifiers#update'
    delete 'related_identifiers/:id/delete', to: 'related_identifiers#delete', as: 'related_identifiers_delete'
    get 'related_identifiers/report', to: 'related_identifiers#report', as: 'related_identifiers_report'
    get 'related_identifiers/show', to: 'related_identifiers#show', as: 'related_identifiers_show'
    get 'related_identifiers/types', to: 'related_identifiers#types'

    get 'geolocation_places/new', to: 'geolocation_places#new'
    post 'geolocation_places/create', to: 'geolocation_places#create'
    delete 'geolocation_places/:id/delete', to: 'geolocation_places#delete', as: 'geolocation_places_delete'

    get 'geolocation_points/new', to: 'geolocation_points#new'
    post 'geolocation_points/create', to: 'geolocation_points#create'
    delete 'geolocation_points/:id/delete', to: 'geolocation_points#delete', as: 'geolocation_points_delete'

    get 'geolocation_boxes/new', to: 'geolocation_boxes#new'
    post 'geolocation_boxes/create', to: 'geolocation_boxes#create'
    delete 'geolocation_boxes/:id/delete', to: 'geolocation_boxes#delete', as: 'geolocation_boxes_delete'

    get 'affiliations/autocomplete', to: 'affiliations#autocomplete'
    get 'affiliations/new', to: 'affiliations#new'
    post 'affiliations/create', to: 'affiliations#create'
    delete 'affiliations/:id/delete', to: 'affiliations#delete', as: 'affiliations_delete'

    get 'licenses/details', to: 'licenses#details', as: 'license_details'

    # Actions through Leaflet Ajax posts
    # points
    get 'geolocation_points/index', to: 'geolocation_points#index'
    get 'geolocation_points/points_coordinates', to: 'geolocation_points#points_coordinates'
    post 'geolocation_points/map_coordinates', to: 'geolocation_points#map_coordinates'
    put 'geolocation_points/update_coordinates', to: 'geolocation_points#update_coordinates'
    delete 'geolocation_points/delete_coordinates', to: 'geolocation_points#delete'
    # bounding boxes
    get 'geolocation_boxes/boxes_coordinates', to: 'geolocation_boxes#boxes_coordinates'
    post 'geolocation_boxes/map_coordinates', to: 'geolocation_boxes#map_coordinates'
    # location names/places
    get 'geolocation_places/places_coordinates', to: 'geolocation_places#places_coordinates'
    post 'geolocation_places/map_coordinates', to: 'geolocation_places#map_coordinates'

    # get composite views or items that begin at the resource level
    get 'metadata_entry_pages/find_or_create', to: 'metadata_entry_pages#find_or_create', as: :datacite_metadata_entry_pages
    get 'resources/review', to: 'resources#review'
    match 'resources/submission' => 'resources#submission', as: :resources_submission, via: :post
    get 'resources/show', to: 'resources#show'

    patch 'peer_review/toggle', to: 'peer_review#toggle', as: :peer_review
    patch 'peer_review/release', to: 'peer_review#release', as: :peer_review_release
  end

  ########################## CEDAR Embeddable Editor ###############################

  post 'metadata_entry_pages/cedar_popup', to: 'metadata_entry_pages#cedar_popup', as: 'cedar_popup'

  # Redirect the calls for MaterialUI icons, since the embeddable editor doesn't know what path it was loaded from
  get '/stash/metadata_entry_pages/MaterialIcons-Regular.woff', to: redirect('/MaterialIcons-Regular.woff')
  get '/stash/metadata_entry_pages/MaterialIcons-Regular.woff2', to: redirect('/MaterialIcons-Regular.woff2')
  get '/stash/metadata_entry_pages/MaterialIcons-Regular.ttf', to: redirect('/MaterialIcons-Regular.ttf')

  get '/cedar-config', to: 'cedar#json_config'
  post '/cedar-save', to: 'cedar#save'

  ########################## Dryad v1 support ######################################

  # Routing to redirect old Dryad URLs to their correct locations in this system
  get '/pages/faq', to: redirect('stash/requirements')
  get '/pages/jdap', to: redirect('docs/JointDataArchivingPolicy.pdf')
  get '/pages/membershipOverview', to: redirect('stash/join_us#our-membership')
  get '/stash/our_membership', to: redirect('stash/join_us#our-membership')
  get '/stash/our_community', to: redirect('stash/join_us#our-membership')
  get '/stash/our_governance', to: redirect('stash/about#our-board')
  get '/stash/our_staff', to: redirect('stash/about#our-staff')
  get '/stash/our_advisors', to: redirect('stash/about#our-advisors')
  get '/stash/our_platform', to: redirect('stash/mission#our-platform')
  get '/stash/our_mission', to: redirect('stash/mission')
  get '/stash/faq', to: redirect('stash/requirements')
  get '/pages/organization', to: redirect('stash/mission')
  get '/pages/policies', to: redirect('stash/terms')
  get '/pages/publicationBlackout', to: redirect('stash/pb_tombstone')
  get '/publicationBlackout', to: redirect('stash/pb_tombstone')
  get '/pages/searching', to: redirect('search')
  get '/themes/Dryad/images/:image', to: redirect('/images/%{image}')
  get '/themes/Dryad/images/dryadLogo.png', to: redirect('/images/logo_dryad.png')
  get '/themes/Mirage/*path', to: redirect('/')
  get '/repo/*path', to: redirect('/')
  get '/repo', to: redirect('/')
  get '/submit', to: redirect { |params, request| "/stash/resources/new?#{request.params.to_query}" }
  get '/interested', to: redirect('/stash/contact#get-involved')
  get '/stash/interested', to: redirect('/stash/contact#get-involved')
  get '/stash/ds_admin', to: redirect('/stash/admin_dashboard')

  # Routing to redirect old Dryad landing pages to the correct location
  # Regex based on https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but a little more restrictive specific to old dryad
  # Dataset:            https://datadryad.org/resource/doi:10.5061/dryad.kq201
  # Version of Dataset: https://datadryad.org/resource/doi:10.5061/dryad.kq201.2
  get '/resource/:doi_prefix/:doi_suffix',
      constraints: { doi_prefix: /doi:10.\d{4,9}/i, doi_suffix: /[A-Z0-9]+\.[A-Z0-9]+/i },
      to: redirect{ |p, req| "stash/dataset/#{p[:doi_prefix]}/#{p[:doi_suffix]}" }
  # File within a Dataset:            https://datadryad.org/resource/doi:10.5061/dryad.kq201/3
  # Version of File within a Dataset: https://datadryad.org/resource/doi:10.5061/dryad.kq201/3.1
  # File within a Version:            https://datadryad.org/resource/doi:10.5061/dryad.kq201.2/3
  # Version of File within a Version: https://datadryad.org/resource/doi:10.5061/dryad.kq201.2/3.1
  get '/resource/:doi_prefix/:doi_suffix*file',
      constraints: { doi_prefix: /doi:10.\d{4,9}/i, doi_suffix: /[A-Z0-9]+\.[A-Z0-9]+/i },
      to: redirect{ |p, req| "stash/dataset/#{p[:doi_prefix]}/#{p[:doi_suffix]}" }

  get :health_check, to: 'health#check'
end

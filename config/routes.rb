Rails.application.routes.draw do

  match '(*any)', to: redirect(subdomain: ''), via: :all, constraints: {subdomain: 'www'}

  use_doorkeeper
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rails routes".

  root :requirements => { :protocol => 'http' }, :to => redirect(path: APP_CONFIG.stash_mount )

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
      to: redirect('https://github.com/CDL-Dryad/dryad-app/tree/main/documentation/v1_wiki_content.md')

  ############################# API support ######################################

  scope module: 'stash_api', path: '/api/v2' do
    # StashApi::GeneralController#index
    get '/', to: 'api#index'
    match '/test', to: 'api#test', via: %i[get post]
    match '/search', to: 'datasets#search', via: %i[get]
    
    # Support for the Editorial Manager API
    match '/em_submission_metadata(/:id)', constraints: { id: /\S+/ }, to: 'datasets#em_submission_metadata', via: %i[post put]

    resources :datasets, shallow: true, id: %r{[^\s/]+?}, format: /json|xml|yaml/, path: '/datasets' do
      member do
        get 'download'
      end
      member do
        post 'set_internal_datum'
      end
      member do
        post 'add_internal_datum'
      end
      resources :internal_data, shallow: true, path: '/internal_data'
      resources :curation_activity, shallow: false, path: '/curation_activity'

      resources :versions, shallow: true, path: '/versions' do
        get 'download', on: :member
        resources :files, shallow: true, path: '/files' do
          get :download, on: :member
        end
      end
            
      resources :urls, shallow: true, path: '/urls', only: [:create]
    end
  
    resources :versions, shallow: true, path: '/versions' do
      get 'download', on: :member
      resources :files, shallow: true, path: '/files' do
        get :download, on: :member
      end
    end

    resources :files, shallow: true, path: '/files' do
      get 'download', on: :member
    end
  
    # this one doesn't follow the pattern since it gloms filename on the end, so manual route
    # This should be PUT, not POST because of filename, see https://stackoverflow.com/questions/630453/put-vs-post-in-rest for example
    put '/datasets/:id/files/:filename', id: %r{[^\s/]+?}, filename: %r{[^\s/]+?}, to: 'files#update', as: 'dataset_file', format: false
    
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
        get 'review'
        get 'upload'
        get 'upload_manifest'
        get 'up_code'
        get 'up_code_manifest'
        get 'submission'
        get 'show_files'
        patch 'import_type'
      end
    end

    resources :identifiers do
      resources :internal_data, shallow: true, as: 'identifier_internal_data'
    end
    match 'identifier_internal_data/:identifier_id', to: 'internal_data#create', as: 'internal_data_create', via: %i[get post put]
    resources :internal_data, shallow: true, as: 'stash_engine_internal_data'
    
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
    
    post 'generic_file/validate_frictionless/:resource_id',
         to: 'generic_files#validate_frictionless',
         as: 'generic_file_validate_frictionless'
    
    get 'dashboard', to: 'dashboard#show', as: 'dashboard'
    get 'ajax_wait', to: 'dashboard#ajax_wait', as: 'ajax_wait'
    get 'metadata_basics', to: 'dashboard#metadata_basics', as: 'metadata_basics'
    get 'preparing_to_submit', to: 'dashboard#preparing_to_submit', as: 'preparing_to_submit'
    get 'upload_basics', to: 'dashboard#upload_basics', as: 'upload_basics'
    get 'react_basics', to: 'dashboard#react_basics', as: 'react_basics'
    
    # download related
    match 'downloads/download_resource/:resource_id', to: 'downloads#download_resource', as: 'download_resource', via: %i[get post]
    match 'downloads/capture_email/:resource_id', to: 'downloads#capture_email', as: 'download_capture_email', via: %i[get post]
    get 'downloads/file_stream/:file_id', to: 'downloads#file_stream', as: 'download_stream'
    get 'downloads/zenodo_file/:file_id', to: 'downloads#zenodo_file', as: 'download_zenodo'
    get 'downloads/preview_csv/:file_id', to: 'downloads#preview_csv', as: 'preview_csv'
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
    match 'session/test_login', to: 'sessions#test_login', via: [:get, :post],  as: 'test_login'
    
    match 'terms/view', to: 'dashboard#view_terms', via: %i[get post]
    
    get 'auth/failure', to: redirect('/')
    match 'sessions/destroy', to: 'sessions#destroy', via: %i[get post]
    get 'sessions/choose_login', to: 'sessions#choose_login', as: 'choose_login'
    get 'sessions/choose_sso', to: 'sessions#choose_sso', as: 'choose_sso'
    post 'sessions/no_partner', to: 'sessions#no_partner', as: 'no_partner'
    post 'sessions/sso', to: 'sessions#sso', as: 'sso'
    
    get 'close_page', to: 'pages#close_page'
    get 'faq', to: 'pages#faq'
    get 'best_practices', to: 'pages#best_practices'
    get 'our_community', to: 'pages#our_membership'
    get 'our_governance', to: 'pages#our_governance'
    get 'our_mission', to: 'pages#our_mission'
    get 'our_membership', to: 'pages#our_membership'
    get 'join_us', to: 'pages#join_us'
    get 'our_platform', to: 'pages#our_platform'
    get 'code_of_conduct', to: 'pages#code_of_conduct'
    get 'ethics', to: 'pages#ethics'
    get 'our_staff', to: 'pages#our_staff'
    get 'our_advisors', to: 'pages#our_advisors'
    get 'pb_tombstone', to: 'pages#pb_tombstone'
    get 'submission_process', to: 'pages#submission_process'
    get 'why_use', to: 'pages#why_use'
    get 'dda', to: 'pages#dda' # data deposit agreement
    get 'search', to: 'searches#index'
    get 'terms', to: 'pages#terms'
    get 'editor', to: 'pages#editor'
    get 'web_crawling', to: 'pages#web_crawling'
    get 'dataset/*id', to: 'landing#show', as: 'show', constraints: { id: /\S+/ }
    get 'landing/citations/:identifier_id', to: 'landing#citations', as: 'show_citations'
    get '404', to: 'pages#app_404', as: 'app_404'
    get 'landing/metrics/:identifier_id', to: 'landing#metrics', as: 'show_metrics'
    get 'test', to: 'pages#test'
    get 'ip_error', to: 'pages#ip_error'
    
    patch 'dataset/*id', to: 'landing#update', constraints: { id: /\S+/ }
    
    # admin user management
    get 'user_admin', to: 'user_admin#index' # main page for administering users
    get 'user_admin/user_profile/:id', to: 'user_admin#user_profile', as: 'user_admin_profile' # page for viewing a single user
    get 'user_admin/role_popup/:id', to: 'user_admin#role_popup', as: 'user_role_popup'
    get 'user_admin/email_popup/:id', to: 'user_admin#email_popup', as: 'user_email_popup'
    get 'user_admin/journals_popup/:id', to: 'user_admin#journals_popup', as: 'user_journals_popup'
    get 'user_admin/tenant_popup/:id', to: 'user_admin#tenant_popup', as: 'user_tenant_popup'
    get 'user_admin/merge_popup', to: 'user_admin#merge_popup', as: 'user_merge_popup'
    post 'user_admin/set_role/:id', to: 'user_admin#set_role', as: 'user_admin_set_role'
    post 'user_admin/set_email/:id', to: 'user_admin#set_email', as: 'user_admin_set_email'
    post 'user_admin/set_tenant/:id', to: 'user_admin#set_tenant', as: 'user_admin_set_tenant'
    post 'user_admin/merge', to: 'user_admin#merge', as: 'user_admin_merge'

    # admin_datasets, aka "Curator Dashboard"
    # this routes actions to ds_admin with a possible id without having to define for each get action, default is index
    get 'ds_admin', to: 'admin_datasets#index'
    get 'ds_admin/index', to: 'admin_datasets#index'
    get 'ds_admin/index/:id', to: 'admin_datasets#index'
    get 'ds_admin/data_popup/:id', to: 'admin_datasets#data_popup'
    get 'ds_admin/note_popup/:id', to: 'admin_datasets#note_popup'
    get 'ds_admin/create_salesforce_case/:id', to: 'admin_datasets#create_salesforce_case', as: 'create_salesforce_case'
    get 'ds_admin/curation_activity_popup/:id', to: 'admin_datasets#curation_activity_popup'
    get 'ds_admin/current_editor_popup/:id', to: 'admin_datasets#current_editor_popup'
    get 'ds_admin/activity_log/:id', to: 'admin_datasets#activity_log'
    get 'ds_admin/stats_popup/:id', to: 'admin_datasets#stats_popup'
    post 'curation_note/:id', to: 'curation_activity#curation_note', as: 'curation_note'
    post 'curation_activity_change/:id', to: 'admin_datasets#curation_activity_change', as: 'curation_activity_change'
    post 'current_editor_change/:id', to: 'admin_datasets#current_editor_change', as: 'current_editor_change'
    
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
    
  end

  # the ones below coming from new routing for geoblacklight
  #--------------------------------------------------------
  mount Geoblacklight::Engine => 'geoblacklight'
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
    post 'contributors/create', to: 'contributors#create'
    patch 'contributors/update', to: 'contributors#update'
    delete 'contributors/:id/delete', to: 'contributors#delete', as: 'contributors_delete'
    
    get 'publications/new', to: 'publications#new'
    get 'publications/autocomplete', to: 'publications#autocomplete'
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
    patch 'fos_subjects/update', to: 'fos_subjects#update'
    
    get 'related_identifiers/new', to: 'related_identifiers#new'
    post 'related_identifiers/create', to: 'related_identifiers#create'
    patch 'related_identifiers/update', to: 'related_identifiers#update'
    delete 'related_identifiers/:id/delete', to: 'related_identifiers#delete', as: 'related_identifiers_delete'
    get 'related_identifiers/report', to: 'related_identifiers#report', as: 'related_identifiers_report'
    get 'related_identifiers/show', to: 'related_identifiers#show', as: 'related_identifiers_show'
    
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
    get 'resources/user_in_progress', to: 'resources#user_in_progress'
    get 'resources/user_submitted', to: 'resources#user_submitted'
    get 'metadata_entry_pages/find_or_create', to: 'metadata_entry_pages#find_or_create', as: :datacite_metadata_entry_pages
    get 'resources/review', to: 'resources#review'
    match 'resources/submission' => 'resources#submission', as: :resources_submission, via: :post
    get 'resources/show', to: 'resources#show'
    
    patch 'peer_review/toggle', to: 'peer_review#toggle', as: :peer_review
  end
  
  ########################## Dryad v1 support ######################################
  
  # Routing to redirect old Dryad URLs to their correct locations in this system
  get '/pages/faq', to: redirect('stash/faq')
  get '/pages/jdap', to: redirect('docs/JointDataArchivingPolicy.pdf')
  get '/pages/membershipOverview', to: redirect('stash/our_membership')
  get '/pages/organization', to: redirect('stash/our_mission')
  get '/pages/policies', to: redirect('stash/terms')
  get '/pages/publicationBlackout', to: redirect('stash/pb_tombstone')
  get '/publicationBlackout', to: redirect('stash/pb_tombstone')
  get '/pages/searching', to: redirect('search')
  get '/themes/Dryad/images/:image', to: redirect('/images/%{image}')
  get '/themes/Dryad/images/dryadLogo.png', to: redirect('/images/logo_dryad.png')
  get '/themes/Mirage/docs/:doc', to: redirect('/docs/%{doc}.%{format}')
  get '/submit', to: redirect("/stash/resources/new")
  
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
end

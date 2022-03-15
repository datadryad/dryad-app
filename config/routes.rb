Rails.application.routes.draw do

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

  mount StashEngine::Engine, at: APP_CONFIG.stash_mount

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

  # the ones below coming from new routing for geoblacklight
  #--------------------------------------------------------
  mount Geoblacklight::Engine => 'geoblacklight'
  mount Blacklight::Engine => '/'

  get '/search', to: 'catalog#index'

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/search', controller: 'catalog' do
    concerns :searchable
  end

  # Probably not needed. I removed the stash_discovery User model,
  # since it did not appear to have any associated code or DB content. (RS)
  #devise_for :users

  # this is kind of hacky, but it directs our search results to open links to the landing pages
  resources :solr_documents, only: [:show], path: '/stash/dataset', controller: 'catalog'

  ########################## Datacite support ######################################

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
    get 'metadata_entry_pages/find_or_create', to: 'metadata_entry_pages#find_or_create'
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

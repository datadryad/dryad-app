Rails.application.routes.draw do

  use_doorkeeper
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rails routes".

  root :requirements => { :protocol => 'http' }, :to => redirect(path: APP_CONFIG.stash_mount )

  #root :requirements => { :protocol => 'https' },
  #     :to => redirect(path: APP_CONFIG.stash_mount, protocol: 'https' )

  #get '/', :requirements => { :protocol => 'http' }, to: redirect(path: APP_CONFIG.stash_mount, protocol: 'http' )

  #get '/', :requirements => { :protocol => 'https' }, to: redirect(path: APP_CONFIG.stash_mount, protocol: 'https' )
  #     constraints: { protocol: 'https' }

  # You can have the root of your site routed with "root"
  #root 'host_pages#index'
  # map.redirect '/', controller: '/stash/pages', action: 'home'
  #match '/auth/:provider/callback', to: 'host_pages#test', via: [:get, :post]

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
  mount StashDatacite::Engine, at: '/stash_datacite'

  # we have to do this to make the geoblacklight routes come before catchall
  # http://blog.arkency.com/2015/02/how-to-split-routes-dot-rb-into-smaller-parts/
  #instance_eval(File.read(StashDiscovery::Engine.root.join("config/routes.rb")))

  # get 'xtf/search', to: 'catalog#index'

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

  # StashApi::GeneralController#index
  get '/api/v2', to: 'api#index'
  match '/api/v2/test', to: 'general#test', via: %i[get post]
  match '/api/v2/search', to: 'datasets#search', via: %i[get]
  
  # Support for the Editorial Manager API
  match '/api/v2/em_submission_metadata(/:id)', constraints: { id: /\S+/ }, to: 'datasets#em_submission_metadata', via: %i[post put]

  scope module: 'stash_api' do
    resources :datasets, shallow: true, id: %r{[^\s/]+?}, format: /json|xml|yaml/, path: '/api/v2/datasets' do
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
        resources :files, shallow: true do
          get :download, on: :member
        end
      end
      resources :urls, shallow: true, path: '/urls', only: [:create]
    end
  
    resources :versions, shallow: true, path: '/api/v2/versions' do
      get 'download', on: :member
      resources :files, shallow: true do
        get :download, on: :member
      end
    end
  end
  
  # this one doesn't follow the pattern since it gloms filename on the end, so manual route
  # This should be PUT, not POST because of filename, see https://stackoverflow.com/questions/630453/put-vs-post-in-rest for example
  put '/api/v2/datasets/:id/files/:filename', id: %r{[^\s/]+?}, filename: %r{[^\s/]+?}, to: 'files#update', as: 'dataset_file', format: false

  resources :users, path: '/api/v2/users', only: %i[index show]

  get '/api/v2/queue_length', to: 'submission_queue#length'

  
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

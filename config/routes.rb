Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  #root :requirements => { :protocol => 'http' },
  #    :to => redirect(path: APP_CONFIG.stash_mount, protocol: 'http' )

  #root :requirements => { :protocol => 'https' },
  #     :to => redirect(path: APP_CONFIG.stash_mount, protocol: 'https' )

  get '/', :requirements => { :protocol => 'http' }, to: redirect(path: APP_CONFIG.stash_mount, protocol: 'http' )

  get '/', :requirements => { :protocol => 'https' }, to: redirect(path: APP_CONFIG.stash_mount, protocol: 'https' )
  #     constraints: { protocol: 'https' }
  
  get '/help' => 'host_pages#help'
  get '/about' => 'host_pages#about'
  
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

  mount StashEngine::Engine, at: APP_CONFIG.stash_mount
  mount StashDatacite::Engine, at: '/stash_datacite'
  # mount StashDiscovery::Engine, at: '/stash_discovery'
end

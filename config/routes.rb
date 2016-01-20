StashDatacite::Engine.routes.draw do


  get 'titles/new', to: 'titles#new'
  post 'titles/create', to: 'titles#create'
  patch 'titles/update', to: 'titles#update'

  get 'descriptions/new', to: 'descriptions#new'
  patch 'descriptions/update', to: 'descriptions#update'

  get 'creators/new', to: 'creators#new'
  post 'creators/create', to: 'creators#create'
  patch 'creators/update', to: 'creators#update'

  get 'resource_types/new', to: 'resource_types#new'
  post 'resource_types/create', to: 'resource_types#create'
  patch 'resource_types/update', to: 'resource_types#update'

  get 'contributors/new', to: 'contributors#new'
  post 'contributors/create', to: 'contributors#create'
  patch 'contributors/update', to: 'contributors#update'

  get 'subjects/new', to: 'subjects#new'
  post 'subjects/create', to: 'subjects#create'
  patch 'subjects/update', to: 'subjects#update'

  get 'related_identifiers/new', to: 'related_identifiers#new'
  post 'related_identifiers/create', to: 'related_identifiers#create'
  patch 'related_identifiers/update', to: 'related_identifiers#update'

  get 'geolocation_places/new', to: 'geolocation_places#new'
  post 'geolocation_places/create', to: 'geolocation_places#create'
  delete 'geolocation_places/:id/delete', to: 'geolocation_places#delete', as: 'geolocation_places_delete'

  get 'geolocation_points/new', to: 'geolocation_points#new'
  post 'geolocation_points/create', to: 'geolocation_points#create'
  delete 'geolocation_points/:id/delete', to: 'geolocation_points#delete', as: 'geolocation_points_delete'

  get 'geolocation_boxes/new', to: 'geolocation_boxes#new'
  post 'geolocation_boxes/map_coordinates', to: 'geolocation_boxes#map_coordinates'
  post 'geolocation_boxes/create', to: 'geolocation_boxes#create'
  delete 'geolocation_boxes/:id/delete', to: 'geolocation_boxes#delete', as: 'geolocation_boxes_delete'

  resources :geolocation_boxes, except: [:index]
  resources :geolocation_points, except: [:index]

end

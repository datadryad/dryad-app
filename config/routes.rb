StashDatacite::Engine.routes.draw do

  get 'titles/new', to: 'titles#new'
  post 'titles/create', to: 'titles#create'
  patch 'titles/update', to: 'titles#update'

  get 'descriptions/new', to: 'descriptions#new'
  patch 'descriptions/update', to: 'descriptions#update'

  get 'creators/new', to: 'creators#new'
  post 'creators/create', to: 'creators#create'
  patch 'creators/update', to: 'creators#update'
  delete 'creators/:id/delete', to: 'creators#delete', as: 'creators_delete'

  get 'contributors/new', to: 'contributors#new'
  post 'contributors/create', to: 'contributors#create'
  patch 'contributors/update', to: 'contributors#update'
  delete 'contributors/:id/delete', to: 'contributors#delete', as: 'contributors_delete'

  get 'resource_types/new', to: 'resource_types#new'
  post 'resource_types/create', to: 'resource_types#create'
  patch 'resource_types/update', to: 'resource_types#update'

  get 'subjects/new', to: 'subjects#new'
  get 'subjects/autocomplete', to: 'subjects#autocomplete'
  post 'subjects/create', to: 'subjects#create'
  delete 'subjects/:id/delete', to: 'subjects#delete', as: 'subjects_delete'

  get 'related_identifiers/new', to: 'related_identifiers#new'
  post 'related_identifiers/create', to: 'related_identifiers#create'
  patch 'related_identifiers/update', to: 'related_identifiers#update'
  delete 'related_identifiers/:id/delete', to: 'related_identifiers#delete', as: 'related_identifiers_delete'

  get 'geolocation_places/new', to: 'geolocation_places#new'
  post 'geolocation_places/create', to: 'geolocation_places#create'
  delete 'geolocation_places/:id/delete', to: 'geolocation_places#delete', as: 'geolocation_places_delete'

  get 'geolocation_points/new', to: 'geolocation_points#new'
  post 'geolocation_points/create', to: 'geolocation_points#create'
  delete 'geolocation_points/:id/delete', to: 'geolocation_points#delete', as: 'geolocation_points_delete'

  get 'geolocation_boxes/new', to: 'geolocation_boxes#new'
  post 'geolocation_boxes/create', to: 'geolocation_boxes#create'
  delete 'geolocation_boxes/:id/delete', to: 'geolocation_boxes#delete', as: 'geolocation_boxes_delete'

  get 'affliations/autocomplete', to: 'affliations#autocomplete'
  get 'affliations/new', to: 'affliations#new'
  post 'affliations/create', to: 'affliations#create'
  delete 'affliations/:id/delete', to: 'affliations#delete', as: 'affliations_delete'

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
  get 'metadata_entry_pages/find_or_create', to: 'metadata_entry_pages#find_or_create'
  get 'resources/review', to: 'resources#review'
end

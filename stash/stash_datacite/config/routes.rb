StashDatacite::Engine.routes.draw do

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

StashDatacite::Engine.routes.draw do


  get 'titles/new', to: 'titles#new'
  post 'titles/create', to: 'titles#create'
  patch 'titles/update', to: 'titles#update'

  resources :creators, except: [:index]
  resources :contributors, except: [:index]
  resources :descriptions, except: [:index]
  resources :resource_types, except: [:index]
  resources :related_identifiers, except: [:index]
  resources :subjects, except: [:index]
  resources :geolocation_boxes, except: [:index]
  resources :geolocation_points, except: [:index]
  resources :geolocation_places, except: [:index]
end

StashDatacite::Engine.routes.draw do

  resources :titles, except: [:index]
  resources :creators, except: [:index]
  resources :descriptions, except: [:index]
  resources :resource_types, except: [:index]
  resources :related_identifiers, except: [:index]
end

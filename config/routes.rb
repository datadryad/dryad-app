StashDatacite::Engine.routes.draw do

  resources :titles, except: [:index]
  resources :creators, except: [:index]
end

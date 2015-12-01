StashDatacite::Engine.routes.draw do

  resources :titles, except: [:index]

end

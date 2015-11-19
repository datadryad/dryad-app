StashDatacite::Engine.routes.draw do

  get   'generals/index', to: 'generals#index'
  match 'generals/find_or_create' => 'generals#find_or_create', via: [:post, :put, :get]
  get   'generals/summary', to: 'generals#summary'

  resources :titles, except: [:index]

end

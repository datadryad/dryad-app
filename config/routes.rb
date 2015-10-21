StashDatacite::Engine.routes.draw do

  get   'generals/index', to: 'generals#index'
  get   'generals/new', to: 'generals#new'
  post  'generals/create', to: 'generals#create'
  get   'generals/edit', to: 'generals#edit'
  put   'generals/update', to: 'generals#update'
  get   'generals/upload', to: 'generals#upload'
  get   'generals/summary', to: 'generals#summary'

end

Rails.application.routes.draw do
  get '/latest', to: 'latest#index', as: 'latest_index'
  # blacklight_for :catalog

  # Endpoint for LinkOut
  get :discover, to: 'catalog#discover'

  # the ones below coming from new routing for geoblacklight
  #--------------------------------------------------------
  mount Geoblacklight::Engine => 'geoblacklight'
  mount Blacklight::Engine => '/'

  get '/search', to: 'catalog#index'
  # root to: "catalog#index" # this seems to be a required route for some layouts, at least the current header

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/search', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users

  # this is kind of hacky, but it directs our search results to open links to the landing pages
  resources :solr_documents, only: [:show], path: '/stash/dataset', controller: 'catalog'
end

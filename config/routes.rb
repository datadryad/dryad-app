require 'blacklight'
require 'geoblacklight'

Rails.application.routes.draw do
  #get '/search', to: 'catalog#index'
  get '/latest', to: 'latest#index', as: 'latest_index'
  # blacklight_for :catalog


  #the ones below coming from new routing for geoblacklight
  #--------------------------------------------------------
  mount Geoblacklight::Engine => 'geoblacklight'
  mount Blacklight::Engine => '/'

  root to: "catalog#index" # this seems to be a required route for some layouts, at least the current header
  #get '/search', to: 'catalog#index'
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/search', controller: 'catalog' do
    concerns :searchable
  end

  #devise_for :users
  #concern :exportable, Blacklight::Routes::Exportable.new

  #resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
  #  concerns :exportable
  #end

  #resources :bookmarks do
  #  concerns :exportable

  #  collection do
  #    delete 'clear'
  #  end
  #end

end

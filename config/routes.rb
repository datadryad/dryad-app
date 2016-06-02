require 'blacklight'
require 'geoblacklight'

Rails.application.routes.draw do
  get '/search', to: 'catalog#index'
  get '/latest', to: 'latest#index', as: 'latest_index'
  blacklight_for :catalog
end

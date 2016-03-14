require 'blacklight'
require 'geoblacklight'

Rails.application.routes.draw do
  get '/search', to: 'catalog#index'
  blacklight_for :catalog
end

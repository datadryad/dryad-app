require 'blacklight'
require 'geoblacklight'

# TODO: Should this be StashDiscovery::Engine.routes? Or just something other than root?
Rails.application.routes.draw do
  get '/search', to: 'catalog#index'
  blacklight_for :catalog
end

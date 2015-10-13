StashEngine::Engine.routes.draw do
  match 'auth/:provider/callback', :to => 'test#after_login', :via => [:get, :post]

  get 'test/after_login'

  get 'test/index'

  root 'test#index'
end

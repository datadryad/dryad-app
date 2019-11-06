require 'blacklight'
require 'geoblacklight'

Rails.application.routes.draw do
  # get '/search', to: 'catalog#index'
  get '/latest', to: 'latest#index', as: 'latest_index'
  # blacklight_for :catalog

  # Endpoint for LinkOut
  get :discover, to: 'catalog#discover'

  # the ones below coming from new routing for geoblacklight
  #--------------------------------------------------------
  mount Geoblacklight::Engine => 'geoblacklight'
  mount Blacklight::Engine => '/'

  # root to: "catalog#index" # this seems to be a required route for some layouts, at least the current header
  get '/search', to: 'catalog#index'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/search', controller: 'catalog' do
    concerns :searchable
  end

  # devise_for :users
  # concern :exportable, Blacklight::Routes::Exportable.new

  # resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
  #  concerns :exportable
  # end

  # resources :bookmarks do
  #  concerns :exportable

  #  collection do
  #    delete 'clear'
  #  end
  # end

  # want to put this in the main app, but load order seems uncontrollable to make it come after and this file loads
  # last with no way to mount it since it's not a mountable/namespaced engine.

  # The URL http://blog.arkency.com/2015/02/how-to-split-routes-dot-rb-into-smaller-parts/
  # might contain a clue, but it would not work for me.  This will go to the 404
  # page as last resort if there is no file in public (static route)

  # Commented out this route since there are too many complexities/problems with this approach
  # and our multi-engines and other things.  Instead put a meta redirect into the static
  # 404.html file to go to our custom app 404 page and make things look nicer without so many problems.

  # unless Rails.env.development? || Rails.env.test?
  # see also http://rubyjunky.com/cleaning-up-rails-4-production-logging.html
  #  #match ":url" => "application#show_404", :constraints => { :url => /.*/ }, via: :all
  #  match '*path', via: :all, to: redirect("#{APP_CONFIG.stash_mount}/404"),
  #    constraints: lambda { |request|
  #      !File.exist?(File.join("#{Rails.root}", 'public', "#{request.env['REQUEST_PATH']}")) &&
  #          "#{request.env['HTTP_ACCEPT']}".match(/text\/html|\*\/\*|text\/\*/)
  #    }
  # end

end

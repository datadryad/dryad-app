StashApi::Engine.routes.draw do

  # use_doorkeeper

  root to: 'general#index'

  match '/test', to: 'general#test', via: %i[get post]
  match '/search', to: 'datasets#search', via: %i[get]

  # Support for the Editorial Manager API
  match '/em_submission_metadata(/:id)', constraints: { id: /\S+/ }, to: 'datasets#em_submission_metadata', via: %i[post put]

  resources :datasets, shallow: true, id: %r{[^\s/]+?}, format: /json|xml|yaml/ do
    member do
      get 'download'
    end
    member do
      post 'set_internal_datum'
    end
    member do
      post 'add_internal_datum'
    end
    resources :internal_data, shallow: true
    resources :curation_activity, shallow: false
    resources :versions, shallow: true do
      get 'download', on: :member
      resources :files, shallow: true do
        get :download, on: :member
      end
    end
    resources :urls, shallow: true, only: [:create]
  end
  # this one doesn't follow the pattern since it gloms filename on the end, so manual route
  # This should be PUT, not POST because of filename, see https://stackoverflow.com/questions/630453/put-vs-post-in-rest for example
  put 'datasets/:id/files/:filename', id: %r{[^\s/]+?}, filename: %r{[^\s/]+?}, to: 'files#update', as: 'dataset_file', format: false

  resources :users, only: %i[index show]

  get '/queue_length', to: 'submission_queue#length'

end

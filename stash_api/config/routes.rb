StashApi::Engine.routes.draw do

  # use_doorkeeper

  root to: 'general#index'

  match '/test', to: 'general#test', via: [:get, :post]

  resources :datasets, shallow: true, id: /[^\s\/]+?/, format: /json|xml|yaml/ do
    get 'download', on: :member
    resources :versions, shallow: true do
      get 'download', on: :member
      resources :internal_data, shallow: true
      resources :files, shallow: true do
        resources :downloads
      end
    end
  end
  # this one doesn't follow the pattern since it gloms filename on the end, so manual route
  # This should be PUT, not POST because of filename, see https://stackoverflow.com/questions/630453/put-vs-post-in-rest for example
  put 'datasets/:id/files/:filename', id: /[^\s\/]+?/, filename: /[^\s\/]+?/, to: 'files#update', as: 'dataset_file', format: false

  resources :users, only: [:index, :show]

end

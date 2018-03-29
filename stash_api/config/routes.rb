StashApi::Engine.routes.draw do

  # use_doorkeeper

  root to: 'general#index'

  match '/test', to: 'general#test', via: [:get, :post]

  resources :datasets, shallow: true, id: /[^\s\/]+?/, format: /json|xml|yaml/ do
    get 'download', on: :member
    resources :versions, shallow: true do
      get 'download', on: :member
      resources :files, shallow: true do
        resources :downloads
      end
    end
  end
  # this one doesn't follow the pattern since it gloms filename on the end, so manual route
  post 'datasets/:id/files/:filename', id: /[^\s\/]+?/, filename: /[^\s\/]+?/, to: 'files#create', as: 'dataset_file', format: false
end

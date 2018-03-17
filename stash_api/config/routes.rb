StashApi::Engine.routes.draw do

  use_doorkeeper
  use_doorkeeper

  root to: 'general#index'

  resources :datasets, shallow: true, id: /[^\s\/]+?/, format: /json|xml|yaml/ do
    get 'download', on: :member
    resources :versions, shallow: true do
      get 'download', on: :member
      resources :files, shallow: true do
        resources :downloads
      end
    end
  end
end

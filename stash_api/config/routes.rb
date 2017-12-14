StashApi::Engine.routes.draw do

  resources :datasets, shallow: true, id: /[^\s\/]+?/, format: /json|xml|yaml/ do
    resources :versions, shallow: true do
      resources :files
    end
  end

end

StashApi::Engine.routes.draw do

  resources :datasets, :id => /[^\s\/]+?/, :format => /json|csv|xml|yaml/

end

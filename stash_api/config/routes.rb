StashApi::Engine.routes.draw do

  resources :datasets, :id => /[^\s\/]+?/, :format => /json|xml|yaml/

end

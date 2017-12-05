Rails.application.routes.draw do

  mount StashApi::Engine => "/stash_api"
end

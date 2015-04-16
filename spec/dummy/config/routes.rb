Rails.application.routes.draw do

  mount Stash::Harvester::Engine => '/harvester'
end

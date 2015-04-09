Rails.application.routes.draw do

  mount Harvester::Engine => "/harvester"
end

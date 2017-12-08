require_dependency "stash_api/application_controller"

module StashApi
  class DatasetsController < ApplicationController

    # get /Dataset/<id>
    def show
      ds = Dataset.new(identifier: params[:id])
      render json: ds.metadata
    end
  end
end

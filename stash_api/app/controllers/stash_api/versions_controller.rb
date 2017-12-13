require_dependency "stash_api/application_controller"

module StashApi
  class VersionsController < ApplicationController

    # get /versions/<id>
    def show
      v = Version.new(resource_id: params[:id])
      respond_to do |format|
        format.json { render json: v.metadata_with_links }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # get /datasets/<dataset-id>/versions
    def index
      respond_to do |format|
        format.json { render json: {hello: 'world'} }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

  end
end

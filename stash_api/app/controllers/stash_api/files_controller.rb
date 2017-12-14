require_dependency 'stash_api/application_controller'

module StashApi
  class FilesController < ApplicationController

    # get /versions/<id>
    def show
      file = StashApi::File.new(file_id: params[:id])
      respond_to do |format|
        format.json { render json: file.metadata }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # get /datasets/<dataset-id>/versions
    def index
      respond_to do |format|
        format.json { render json: { hello: 'world' } }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end
  end
end

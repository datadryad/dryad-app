require_dependency "stash_datacite/application_controller"

module StashDatacite
  class GeneralsController < ApplicationController

        # GET /generals
    def index
      @resources = StashDatacite.resource_class.all
    end

    def show
    end

    def new
      @resources = StashDatacite.resource_class.all
    end

    def edit
      @resources = StashDatacite.resource_class.all
    end


    # POST /generals/create
    def create
      @resource = StashDatacite.resource_class.find(generals_params[:resource_id].to_i)

    end

    def destroy
    end

    def upload
    end

    def summary
    end

    private

      def generals_params
        params.require(:general).permit(:resource_id)
      end
  end
end

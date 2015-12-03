require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class CreatorsController < ApplicationController
    before_action :set_creator, only: [:show, :edit, :update, :destroy]

    # GET /creators
    def index
      @creators = Creator.all
    end

    # GET /creators/1
    def show
    end

    # GET /creators/new
    def new
      @creator = Creator.new
    end

    # GET /creators/1/edit
    def edit
    end

    # POST /creators
    def create
      @creator = Creator.new(creator_params)
      respond_to do |format|
        if @creator.save
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /creators/1
    def update
      respond_to do |format|
        if @creator.update(creator_params)
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # DELETE /creators/1
    def destroy
      @creator.destroy
      redirect_to creators_url, notice: 'Creator was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_creator
      @creator = Creator.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def creator_params
      params.require(:creator).permit(:creator_name, :name_identifier_id, :affliation_id, :resource_id)
    end
  end
end

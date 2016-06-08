require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class CreatorsController < ApplicationController
    before_action :set_creator, only: [:update]

    respond_to :json

    # GET /creators/new
    def new
      @creator = Creator.new(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    # POST /creators
    def create
      @affliation = Affliation.where('long_name LIKE ? OR short_name LIKE ? OR abbreviation LIKE?',
                                       "%#{creator_params[:affliation]}%", "%#{creator_params[:affliation]}%", "%#{creator_params[:affliation]}%") unless params[:affliation].blank?
      if @affliation.nil?
        Affliation.create(long_name: params[:affliation])
      end
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
      @affliation = Affliation.where('long_name LIKE ? OR short_name LIKE ? OR abbreviation LIKE?',
                                       "%#{params[:affliation]}%", "%#{params[:affliation]}%", "%#{params[:affliation]}%") unless params[:affliation].blank?
      if @affliation.nil?
        Affliation.create(long_name: params[:affliation])
      end
      respond_to do |format|
        if @creator.update(creator_params)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end

    # DELETE /creators/1
    def delete
      unless params[:id] == 'new'
        @creator = Creator.find(params[:id])
        @resource = StashDatacite.resource_class.find(@creator.resource_id)
        @creator.destroy
      end
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_creator
      @creator = Creator.find(creator_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def creator_params
      params.require(:creator).permit(:id, :creator_first_name, :creator_last_name, :creator_middle_name,
                                      :name_identifier_id, :affliation_id, :resource_id, :orcid_id)
    end
  end
end

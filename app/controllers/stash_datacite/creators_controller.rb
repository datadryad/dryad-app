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
      duplicate_affiliation = Affiliation.where('long_name LIKE ? OR short_name LIKE ?',
                                           "#{params[:affiliation]}", "#{params[:affiliation]}").first
      @creator = Creator.new(creator_params)
      respond_to do |format|
        @creator.save
        @creator.reload
        unless duplicate_affiliation.present?
          if params[:affiliation].present?
            @affiliation = Affiliation.create(long_name: params[:affiliation])
            @creator.affiliation_id = @affiliation.id
            @creator.save
          else
            ''
          end
        end
        format.js
      end
    end

    # PATCH/PUT /creators/1
    def update
      duplicate_affiliation = Affiliation.where('long_name LIKE ? OR short_name LIKE ?',
                                           "#{params[:affiliation]}", "#{params[:affiliation]}").first
      respond_to do |format|
        unless duplicate_affiliation.present?
          @creator.update(creator_params)
          @creator.reload
          if params[:affiliation].present?
            @affiliation = Affiliation.create(long_name: params[:affiliation])
            @creator.affiliation_id = @affiliation.id
            @creator.save
          else
            ''
          end
        else
          @creator.update(creator_params)
        end
        format.js { render template: 'stash_datacite/shared/update.js.erb' }
      end
    end

    # DELETE /creators/1
    def delete
      unless params[:id] == 'new'
        @creator = Creator.find(params[:id])
        @resource = StashDatacite.resource_class.find(@creator.resource_id)
        @if_orcid = check_for_orcid_id(@creator)
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
                                      :name_identifier_id, :affiliation_id, :resource_id, :orcid_id)
    end

    def check_for_orcid_id(creator)
      if creator.orcid_id
        return true
      else
        return false
      end
    end
  end
end

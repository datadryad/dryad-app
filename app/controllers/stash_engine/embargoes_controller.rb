require_dependency 'stash_engine/application_controller'

module StashEngine
  class EmbargoesController < ApplicationController
    before_action :set_embargo, only: [:delete]

    # GET /embargos/new
    def new
      @embargo = Embargo.new(resource_id: params[:resource_id])
    end

    # GET /embargos/1/edit
    def edit; end

    # POST /embargos
    def create
      @embargo = Embargo.new(embargo_params)
      respond_to do |format|
        if @embargo.save
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /embargos/1
    def update
      @embargo = Embargo.where(resource_id: embargo_params[:resource_id]).first
      @resource = Resource.find(embargo_params[:resource_id])
      respond_to do |format|
        unless embargo_params[:end_date].to_date == Date.today.to_date
          @embargo.update(embargo_params)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          @embargo.destroy
          format.js { render 'delete' }
        end
      end
    end

    # DELETE /embargos/1
    def delete
      @embargo.destroy
      respond_to do |format|
        format.js
      end
    end

    # this is a generic action to handle all create/modify/delete actions for an embargo since it's just one form
    # and using the rest methods in this case is overly complicated and annoying
    def changed
      byebug
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_embargo
      @embargo = Embargo.find(embargo_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def embargo_params
      params.require(:embargo).permit(:id, :end_date, :resource_id)
    end
  end
end

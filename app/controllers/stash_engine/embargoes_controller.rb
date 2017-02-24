require_dependency "stash_engine/application_controller"

module StashEngine
  class EmbargoesController < ApplicationController
    before_action :set_embargo, only: [:edit, :update, :delete]

    resspond_to :json

    # GET /embargos/new
    def new
      @embargo = Embargo.new(resource_id: params[:resource_id])
    end

    # GET /embargos/1/edit
    def edit
    end

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
      respond_to do |format|
        if @embargo.update(embargo_params)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
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

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_embargo
        @embargo = Embargo.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def embargo_params
        params[:embargo]
      end
  end
end

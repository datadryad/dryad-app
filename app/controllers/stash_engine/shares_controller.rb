require_dependency "stash_engine/application_controller"

module StashEngine
  class SharesController < ApplicationController
    # before_action :set_share, only: [:edit, :update, :delete]

    # GET /shares/1/edit
    def edit
    end

    # POST /shares
    def create
      ## creates a new share object with resource_id as params
      @share = Share.new(resource_id: params[:resource_id])
      respond_to do |format|
        if @share.save
          format.js
        else
          format.html { render 'new' }
        end
      end
    end

    # PATCH/PUT /shares/1
    def update
      @share = Share.where(id: params[:id], resource_id: params[:resource_id]).first
      respond_to do |format|
        if @share.save
          format.js
        else
          format.html { render 'edit' }
        end
      end
    end

    # DELETE /shares/1
    def delete
      @share.destroy
      respond_to do |format|
        format.js
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      # def set_share
      #   @share = Share.find(params[:id])
      # end

      # Only allow a trusted parameter "white list" through.
      def share_params
        params.require(:share).permit(:id, :secret_id, :expiration_date, :resource_id)
      end
  end
end

require_dependency 'stash_engine/application_controller'

module StashEngine
  class SharesController < ApplicationController

    # GET /shares/1
    def show
      @share = Share.where(id: params[:id], identifier_id: params[:identifier_id]).first
      respond_to do |format|
        format.js
      end
    end
  end
end

require 'stash_datacite/application_controller'

module StashDatacite
  class TitlesController < ApplicationController

    before_action :ajax_require_modifiable, only: [:update]

    respond_to :json

    # PATCH/PUT /titles/1
    def update
      respond_to do |format|
        if resource.update(title: params[:title])
          format.json { render json: @resource.slice(:id, :title) }
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def resource
      @resource ||= StashEngine::Resource.find(params[:id])
    end
  end
end

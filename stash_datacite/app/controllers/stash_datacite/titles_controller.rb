require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class TitlesController < ApplicationController

    respond_to :json

    # PATCH/PUT /titles/1
    def update
      @resource = StashEngine::Resource.find(params[:id])
      respond_to do |format|
        if @resource.update(title: params[:title])
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end
  end
end

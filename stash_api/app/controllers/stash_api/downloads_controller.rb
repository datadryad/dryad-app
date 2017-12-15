require_dependency 'stash_api/application_controller'

module StashApi
  class DownloadsController < ApplicationController

    # get /download/<id>
    def show
      f = StashEngine::FileUpload.find(params[:id])
      respond_to do |format|
        format.html do
          redirect_to f.merritt_url
        end
      end
    end

  end
end

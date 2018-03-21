# frozen_string_literal: true

require_dependency 'stash_api/application_controller'

module StashApi
  class DownloadsController < ApplicationController

    before_action -> { require_file_id(file_id: params[:id]) }, only: [:show]

    # get /download/<id>
    def show
      f = StashEngine::FileUpload.find(params[:id])
      respond_to do |format|
        format.html do
          StashEngine::CounterLogger.general_hit(request: request, file: f)
          redirect_to f.merritt_url
        end
      end
    end

  end
end

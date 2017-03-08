require_dependency 'stash_engine/application_controller'

module StashEngine
  class DownloadsController < ApplicationController

    def download_resource
      @resource = Resource.find(params[:resource_id])
      if @resource.under_embargo?
        # if you're the owner do streaming download
        if current_user && current_user.id == @resource.user_id
          stream_response(@resource.merritt_producer_download_uri,
              current_user.tenant.repository.username,
              current_user.tenant.repository.password)
        end
      else
        # redirect to the producer file download link
        redirect_to @resource.merritt_producer_download_uri
      end
    end

  end
end

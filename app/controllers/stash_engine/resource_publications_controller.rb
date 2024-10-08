module StashEngine
  class ResourcePublicationsController < ApplicationController
    before_action :require_user_login

    def index; end

    def create; end

    def update
      @publication = authorize StashEngine::ResourcePublication.find(params[:id])
      @publication.update(up_params)
      respond_to(&:js)
    end

    def destroy; end

    private

    def up_params
      p = params.permit(stash_engine_resource_publication: %i[publication_name publication_issn manuscript_number])
      p[:stash_engine_resource_publication]
    end
  end
end

module StashEngine
  class ResourcePublicationsController < ApplicationController
    before_action :require_user_login

    def index; end

    def create; end

    def update
      publication = authorize StashEngine::ResourcePublication.find(params[:id])
      publication.update(up_params)
      respond_to do |format|
        format.js do
          @resource = StashEngine::Resource.find(publication.resource_id)
          @related_work = StashDatacite::RelatedIdentifier.new(resource_id: @resource.id)
          @publication = StashEngine::ResourcePublication.find_or_create_by(resource_id: @resource.id, pub_type: :primary_article)
          @preprint = StashEngine::ResourcePublication.find_or_create_by(resource_id: @resource.id, pub_type: :preprint)
          render template: 'stash_engine/admin_datasets/publications_reload', formats: [:js]
        end
      end
    end

    def destroy; end

    private

    def up_params
      p = params.permit(stash_engine_resource_publication: %i[publication_name publication_issn manuscript_number])
      p[:stash_engine_resource_publication]
    end
  end
end

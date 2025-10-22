module StashEngine
  class ResourcePublicationsController < ApplicationController
    include PublicationMixin

    before_action :require_user_login

    def index; end

    def create; end

    def update
      publication = authorize StashEngine::ResourcePublication.find(params[:id])
      publication.update(up_params)
      @resource = StashEngine::Resource.find(publication.resource_id)
      check_resource_payment(@resource)
      release_resource(@resource) if @resource.identifier&.has_accepted_manuscript?
      respond_to do |format|
        format.js do
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
      pa = params.permit(stash_engine_resource_publication: %i[publication_name publication_issn manuscript_number])
      pa[:stash_engine_resource_publication]
    end
  end
end

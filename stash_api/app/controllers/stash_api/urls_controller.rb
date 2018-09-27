require_dependency 'stash_api/application_controller'

# rubocop:disable Metrics/ClassLength
module StashApi
  class UrlsController < ApplicationController

    before_action -> { require_stash_identifier(doi: params[:dataset_id]) }, only: %i[create]
    before_action :doorkeeper_authorize!, only: :create
    before_action :require_api_user, only: :create
    before_action :require_in_progress_resource, only: :create
    before_action :require_permission, only: :create

    # { url: 'https://crackpot.com',
    #   skipValidation: true/false (only available to superusers),
    #   if not validated then the following items need to be supplied
    #   size: 18288,
    #   mimeType: 'application/pdf' }
    #   The path will be derived from the URL and the status will be created
    def create
      byebug
      respond_to do |format|
        format.json { render json: file.metadata, status: 201 }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

  end
end
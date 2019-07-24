require_dependency 'stash_api/application_controller'
require_dependency 'stash_api/datasets_controller'

module StashApi
  class CurationActivityController < ApplicationController
    before_action :require_json_headers
    before_action :doorkeeper_authorize!
    before_action :require_api_user
    before_action :require_curator
    before_action -> { initialize_stash_identifier(params[:dataset_id]) }, only: %i[index create]

    # In the API, the output will include the user and dataset, but you can't actually set those via the API
    # Identifier_id/dataset will be set by the :dataset_id in the params when the record is created
    # User_id will be set to the API user when the record is created.

    # GET /curation_activity/{id}
    def show
      @curation_activity = StashEngine::CurationActivity.find(params[:id])
      respond_to do |format|
        format.json { render json: @curation_activity }
      end
    end

    # GET /datasets/{dataset_id}/curation_activity
    def index
      @curation_activity = StashEngine::CurationActivity.where(resource_id: @stash_identifier.latest_resource.id)
      @curation_activity = @curation_activity.where(status: params[:status]) if params.key?(:status)
      @curation_activity = @curation_activity.where(user_id: @user.id) if params.key?(:user_id)
      @curation_activity = @curation_activity.order(updated_at: :desc)
      respond_to do |format|
        format.json { render json: @curation_activity }
      end
    end

    # POST /datasets/{dataset_id}/curation_activity
    def create
      params.permit!
      resource = StashEngine::Identifier.find_with_id(params[:dataset_id]).latest_resource
      create_curation_activity(resource)
      respond_to do |format|
        format.json { render json: resource&.reload&.current_curation_activity }
      end
    end

    # PUT /curation_activity/{id}
    def update
      params.permit!
      resource = StashEngine::Identifier.find(params[:dataset_id]).latest_resource
      create_curation_activity(resource)
      respond_to do |format|
        format.json { render json: resource&.reload&.current_curation_activity }
      end
    end

    # DELETE /curation_activity/{id}
    def destroy
      StashEngine::CurationActivity.destroy(params[:id])
      render json: { status: 'Curation activity with identifier ' + params[:id] + ' has been successfully deleted.' }.to_json, status: 200
    end

    def initialize_stash_identifier(id)
      ds = DatasetsController.new
      @stash_identifier = ds.get_stash_identifier(id)
      render json: { error: 'cannot find dataset with identifier ' + id }.to_json, status: 404 if @stash_identifier.nil?
    end

    private

    # Publish, embargo or simply change the status
    def create_curation_activity(resource)
      return unless resource.present?

      case params[:curation_activity][:status]
      when 'published'
        record_published_date(resource)
      when 'embargoed'
        record_embargoed_date(resource)
      end

      StashEngine::CurationActivity.create(resource_id: resource.id,
                                           user_id: params[:user_id] || @user.id,
                                           status: params[:curation_activity][:status],
                                           note: params[:curation_activity][:note],
                                           created_at: params[:curation_activity][:created_at] || Time.now.utc)
    end

    def record_published_date(resource)
      return if resource.publication_date.present?
      publish_date = params[:curation_activity][:created_at] || Time.now.utc
      resource.update!(publication_date: publish_date)
    end

    def record_embargoed_date(resource)
      # If the curation activity has an explicit publication date, use that,
      # regardless of whether a publication date has been set otherwise.
      explicit_pub_date = params[:curation_activity][:note].match(/PublicationDate=(\d+-\d+-\d+)/)
      if explicit_pub_date
        begin
          resource.update!(publication_date: explicit_pub_date[1].to_date)
          return
        rescue StandardError
          # If the explicit publication date is invalid, ignore it and handle as it if is absent.
          nil
        end
      end

      return if resource.publication_date.present?
      embargo_date = (params[:curation_activity][:created_at]&.to_date || Date.today) + 1.year
      resource.update!(publication_date: embargo_date)
    end

  end
end

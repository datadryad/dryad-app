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
      @curation_activity = StashEngine::CurationActivity.where(identifier_id: @stash_identifier.id)
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
      @curation_activity = StashEngine::CurationActivity.new(params[:curation_activity].except(:identifier_id, :user_id, :dataset))
      @curation_activity.update!(user_id: @user.id, identifier_id: @stash_identifier.id)
      @curation_activity.update!(user_id: nil) if params[:user_id].nil?
      render json: @curation_activity
    end

    # PUT /curation_activity/{id}
    def update
      params.permit!
      @curation_activity = StashEngine::CurationActivity.find(params[:id])
      @curation_activity.update!(params[:curation_activity].except(:identifier_id, :user_id, :dataset))
      @curation_activity.update!(user_id: nil) if params[:user_id].nil?
      respond_to do |format|
        format.json { render json: @curation_activity }
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
  end
end

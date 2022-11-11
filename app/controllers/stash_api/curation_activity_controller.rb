module StashApi
  class CurationActivityController < ApiApplicationController
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
      render json: @curation_activity
    end

    # GET /datasets/{dataset_id}/curation_activity
    def index
      @curation_activity = StashEngine::CurationActivity.where(resource_id: @stash_identifier.latest_resource.id)
      @curation_activity = @curation_activity.where(status: params[:status]) if params.key?(:status)
      @curation_activity = @curation_activity.where(user_id: @user.id) if params.key?(:user_id)
      @curation_activity = @curation_activity.order(updated_at: :desc)
      render json: @curation_activity
    end

    # POST /datasets/{dataset_id}/curation_activity
    def create
      resource = StashEngine::Identifier.find_with_id(params[:dataset_id]).latest_resource
      create_curation_activity(resource)
      render json: resource&.reload&.last_curation_activity
    end

    # PUT /curation_activity/{id}
    def update
      resource = StashEngine::Identifier.find(params[:dataset_id]).latest_resource
      create_curation_activity(resource)
      render json: resource&.reload&.last_curation_activity
    end

    # DELETE /curation_activity/{id}
    def destroy
      StashEngine::CurationActivity.destroy(params[:id])
      render json: { status: "Curation activity with identifier #{params[:id]} has been successfully deleted." }.to_json, status: 200
    end

    def initialize_stash_identifier(id)
      ds = StashApi::DatasetsController.new
      @stash_identifier = ds.get_stash_identifier(id)
      render json: { error: "cannot find dataset with identifier #{id}" }.to_json, status: 404 if @stash_identifier.nil?
    end

    private

    # Publish, embargo or simply change the status
    def create_curation_activity(resource)
      return unless resource.present?

      ca_status = params[:curation_activity][:status]
      ca_note = params[:curation_activity][:note]

      case ca_status
      when 'published'
        record_published_date(resource)
      when 'embargoed'
        record_embargoed_date(resource)
      end

      ca_user = if ca_note&.match(/based on notification from journal/)
                  0
                else
                  params[:user_id] || @user.id
                end

      # if the status is being updated based on notification from a journal, DON'T go backwards in workflow,
      # that is, don't change a status other than submitted or peer_review
      if ca_note&.match(/based on notification from journal/) &&
         !%w[submitted peer_review].include?(resource.current_curation_status)
        ca_note = "received notification from journal module that the associated manuscript is #{ca_status}, " \
                  "but the dataset is #{resource.current_curation_status}, so it will retain that status"
        ca_status = resource.current_curation_status
      end

      StashEngine::CurationActivity.create(resource_id: resource.id,
                                           user_id: ca_user,
                                           status: ca_status,
                                           note: ca_note,
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

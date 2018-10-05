# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require_dependency 'stash_api/application_controller'
require_relative 'datasets/submission_mixin'

module StashApi
  class DatasetsController < ApplicationController

    include SubmissionMixin

    before_action :require_json_headers, only: %i[show create index update]
    before_action -> { require_stash_identifier(doi: params[:id]) }, only: %i[show download]
    before_action :setup_identifier_and_resource_for_put, only: %i[update]
    before_action :doorkeeper_authorize!, only: %i[create update]
    before_action :require_api_user, only: %i[create update]
    # before_action :require_in_progress_resource, only: :update
    before_action :require_permission, only: :update
    before_action :lock_down_admin_only_params, only: %i[create update]

    # get /datasets/<id>
    def show
      ds = Dataset.new(identifier: @stash_identifier.to_s)
      respond_to do |format|
        format.json { render json: ds.metadata }
        res = @stash_identifier.last_submitted_resource
        StashEngine::CounterLogger.general_hit(request: request, resource: res) if res
      end
    end

    # post /datasets
    def create
      respond_to do |format|
        format.json do
          dp = DatasetParser.new(hash: params['dataset'], id: nil, user: @user)
          @stash_identifier = dp.parse
          ds = Dataset.new(identifier: @stash_identifier.to_s) # sets up display objects
          render json: ds.metadata, status: 201
        end
      end
    end

    # get /datasets
    def index
      datasets = paged_datasets
      respond_to do |format|
        format.json { render json: datasets }
      end
    end

    # we are using PATCH only to update the versionStatus=submitted
    # PUT will be to update/replace the dataset metadata
    # put/patch /datasets/<id>
    # we are also allowing UPSERT with a PUT as in the pattern at
    # https://www.safaribooksonline.com/library/view/restful-web-services/9780596809140/ch01s09.html or
    # https://stackoverflow.com/questions/18470588/in-rest-is-post-or-put-best-suited-for-upsert-operation
    # rubocop:disable Metrics/MethodLength
    def update
      do_patch { return } # check if patch and do submission and return early if it is a patch (submission)
      # otherwise this is a PUT of the dataset metadata
      check_status { return } # check it's in progress, clone a submitted or raise an error
      respond_to do |format|
        format.json do
          dp = if @resource
                 DatasetParser.new(hash: params['dataset'], id: @resource.identifier, user: @user) # update dataset
               else
                 DatasetParser.new(hash: params['dataset'], user: @user, id_string: params[:id]) # upsert dataset with identifier
               end
          @stash_identifier = dp.parse
          ds = Dataset.new(identifier: @stash_identifier.to_s) # sets up display objects
          render json: ds.metadata, status: 200
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # get /datasets/<id>/download
    def download
      res = @stash_identifier.last_submitted_resource
      if res&.download_uri
        res = @stash_identifier.last_submitted_resource
        StashEngine::CounterLogger.version_download_hit(request: request, resource: res) if res
        redirect_to res.merritt_producer_download_uri # latest version, friendly download because that's what we do in UI for object
      else
        render text: 'download for this dataset is unavailable', status: 404
      end
    end

    def get_stash_identifier(id)
      # check to see if the identifier is actually an id and not a DOI first
      return StashEngine::Identifier.where(id: id).first if id.match?(/^\d+$/)
      id_type, id_text = id.split(':', 2)
      render json: { error: 'incorrect DOI format' }.to_json, status: 404 if !id_type.casecmp('DOI').zero? || !id_text.match(%r{^10\.\S+/\S+$})
      StashEngine::Identifier.where(identifier_type: id_type.upcase).where(identifier: id_text).first
    end

    def initialize_stash_identifier(id)
      @stash_identifier = get_stash_identifier(id)
      render json: { error: 'cannot find dataset with identifier ' + id }.to_json, status: 404 if @stash_identifier.blank?
    end

    private

    def setup_identifier_and_resource_for_put
      @stash_identifier = get_stash_identifier(params[:id])
      @resource = @stash_identifier.resources.by_version_desc.first unless @stash_identifier.blank?
    end

    def do_patch
      return unless request.method == 'PATCH' && request.headers['content-type'] == 'application/json-patch+json'
      check_patch_prerequisites { yield }
      check_dataset_completions { yield }
      pre_submission_updates
      StashEngine.repository.submit(resource_id: @resource.id)
      # render something
      ds = Dataset.new(identifier: @stash_identifier.to_s)
      render json: ds.metadata, status: 202
      yield
    end

    # checks the status for allowing a dataset PUT request that is an update
    def check_status
      return if @stash_identifier.nil? || @resource.nil?
      state = @resource.current_resource_state.try(:resource_state)
      return if state == 'in_progress'
      return_error(messages: 'Your dataset cannot be updated now', status: 403) { yield } if state != 'submitted'
      duplicate_resource # because we're starting a new version
    end

    # some parameters would be locked down for only admins or superusers to set
    def lock_down_admin_only_params
      # all this bogus return false stuff is to prevent double render errors in some circumstances
      return if check_skip_datacite_update_permission == false
      return if check_may_set_user_id == false
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def check_skip_datacite_update_permission
      skip_dc_update = params['skipDataciteUpdate']
      unless skip_dc_update.nil? || skip_dc_update.class == TrueClass || skip_dc_update.class == FalseClass
        render json: { error: 'Bad Request: skipDataciteUpdate must be true or false' }.to_json, status: 400
        return false
      end
      return if %w[admin superuser].include?(@user.role) || skip_dc_update == false || skip_dc_update.nil?
      render json: { error: 'Unauthorized: only administrative roles may skip updating their DataCite metadata' }.to_json, status: 401
      false
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def check_may_set_user_id
      return if params['userId'].nil?
      unless @user.role == 'superuser' || params['userId'].to_i == @user.id # or it is your own user
        render json: { error: 'Unauthorized: only superuser roles may set a specific user' }.to_json, status: 401
        return false
      end
      users = StashEngine::User.where(id: params['userId'])
      return if users.count == 1
      render(json: { error: 'Bad Request: the userId you chose is invalid' }.to_json, status: 400)
      false
    end

    def duplicate_resource
      nr = @resource.amoeba_dup
      nr.current_editor_id = @user.id
      nr.save!
      @resource = nr
    end

    def all_datasets
      { 'stash:datasets' =>
          StashEngine::Identifier.all.map { |i| Dataset.new(identifier: "#{i.identifier_type}:#{i.identifier}").metadata } }
    end

    def paged_datasets
      all_count = StashEngine::Identifier.all.count
      results = StashEngine::Identifier.all.limit(page_size).offset(page_size * (page - 1))
      results = results.map { |i| Dataset.new(identifier: "#{i.identifier_type}:#{i.identifier}").metadata }
      paging_hash_results(all_count, results)
    end

    def paging_hash_results(all_count, results)
      {
        '_links' => paging_hash(result_count: all_count),
        count: results.count,
        total: all_count,
        '_embedded' => { 'stash:datasets' => results }
      }
    end

  end
end

# rubocop:enable Metrics/ClassLength

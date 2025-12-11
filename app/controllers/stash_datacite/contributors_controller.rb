require 'http'
module StashDatacite
  class ContributorsController < ApplicationController
    before_action :check_reorder_valid, only: %i[reorder]
    before_action :set_contributor, only: %i[update delete]
    before_action :ajax_require_modifiable, only: %i[update create delete reorder]

    respond_to :json

    # GET /contributors/new
    def new
      @contributor = Contributor.new(resource_id: params[:resource_id])
      respond_to(&:js)
    end

    # POST /contributors
    def create
      @contributor = Contributor.new(contributor_params)
      respond_to do |format|
        if @contributor.save
          check_reindex
          format.json do
            render json: @contributor.as_json(methods: [:api_integration_key])
          end
          format.js do
            @funder = Contributor.new(resource_id: params[:resource_id])
            render template: 'stash_engine/admin_datasets/funders_reload', formats: [:js]
          end
        end
      end
    end

    # PATCH/PUT /contributors/1
    def update
      respond_to do |format|
        contributor_params[:contributor_name] = contributor_params[:contributor_name].squish if contributor_params[:contributor_name].present?
        contributor_params[:award_description] = contributor_params[:award_description].squish if contributor_params[:award_description].present?
        contributor_params[:award_title] = contributor_params[:award_title].squish if contributor_params[:award_title].present?
        if @contributor.update(contributor_params)
          # check_details
          check_reindex
          format.json do
            render json: @contributor.as_json(methods: [:api_integration_key])
          end
          format.js do
            @funder = Contributor.new(resource_id: params[:resource_id])
            render template: 'stash_engine/admin_datasets/funders_reload', formats: [:js]
          end
        else
          format.any(:js, :json) { render json: @contributor.errors.messages, status: 406 }
        end
      end
    end

    # DELETE /contributors/1
    def delete
      unless params[:id] == 'new'
        @contributor = Contributor.find(params[:id])
        @contributor.destroy
      end
      respond_to do |format|
        format.json { render json: @contributor }
        format.js do
          @funder = Contributor.new(resource_id: params[:resource_id])
          render template: 'stash_engine/admin_datasets/funders_reload', formats: [:js]
        end
      end
    end

    # takes a list of funder ids and their new orders like [{id: 3323, order: 0},{id:3324, order: 1}] etc
    def reorder
      respond_to do |format|
        format.json do
          js = params[:contributor].to_h.to_a.map { |i| { id: i[0], funder_order: i[1] } }
          grouped_funders = js.index_by { |funder| funder[:id] }
          resp = Contributor.update(grouped_funders.keys, grouped_funders.values)
          render json: resp, status: :ok
        end
      end
    end

    # GET /contributors/autocomplete?query={query_term}
    def autocomplete
      # Limited to existing funder selections — not currently used
      partial_term = params['query']
      if partial_term.blank?
        render json: nil
      else
        contributors = StashEngine::RorOrg.find_by_ror_name(partial_term, limit: 300)
        funder_ids = StashDatacite::Contributor.funder.where(name_identifier_id: contributors.map { |a| a[:id] }).distinct.pluck(:name_identifier_id)
        render json: contributors.select { |a| a[:id].in?(funder_ids) }
      end
    end

    # POST /contributors/grouping?ror_id={ror_id}
    def grouping
      grouping = StashDatacite::ContributorGrouping.where(name_identifier_id: params[:ror_id]).first
      render json: grouping
    end

    private

    def resource
      @resource ||= (params[:contributor] ? StashEngine::Resource.find(contributor_params[:resource_id]) : @contributor.resource)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def check_reindex
      return unless @resource.current_curation_status == 'published'

      @resource.submit_to_solr
      DataciteService.new(@resource).submit
    end

    def check_details
      return unless @contributor.auto_update?

      award_info = AwardMetadataService.new(@contributor).award_details || {}
      return unless award_info.present?

      @contributor.update(award_info)
      @contributor.reload
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_contributor
      return if params[:id] == 'new'

      @contributor = Contributor.find((params[:contributor] ? params[:contributor][:id] : params[:id]))
      ajax_blocked unless resource.id == @contributor.resource_id
    end

    # Only allow a trusted parameter "white list" through.
    def contributor_params
      params.require(:contributor).permit(
        :id, :contributor_name, :contributor_type, :identifier_type, :name_identifier_id, :affiliation_id, :funder_order, :resource_id,
        :award_number, :award_uri, :award_title, :award_description
      )
    end

    def check_reorder_valid
      params.require(:contributor).permit!
      @contributors = Contributor.where(id: params[:contributor].keys)

      # you can only order things belonging to one resource
      render json: { error: 'bad request' }, status: :bad_request unless @contributors.map(&:resource_id)&.uniq&.length == 1

      @resource = StashEngine::Resource.find(@contributors.first.resource_id) # set resource to check permission to modify
    end
  end
end

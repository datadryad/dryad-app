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
      @contributor = find_or_initialize
      respond_to do |format|
        if @contributor.save
          check_reindex
          format.json { render json: @contributor }
          format.js do
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
          check_details
          check_reindex
          format.json { render json: @contributor }
          format.js do
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
      # Limited to existing funder selections — only used on admin dashboard currently
      partial_term = params['query']
      if partial_term.blank?
        render json: nil
      else
        @contributors = StashEngine::RorOrg.distinct.joins(
          "inner join dcs_contributors on identifier_type = 'ror' and contributor_type = 'funder' and name_identifier_id = ror_id"
        ).find_by_ror_name(partial_term)
        render json: @contributors
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

    def find_or_initialize
      # If it's the same as the previous one, but the award number changed from blank to non-blank, just add the award number
      contrib_name = contributor_params[:contributor_name].squish
      unless contrib_name.blank?
        contributor = Contributor.where('resource_id = ? AND (contributor_name = ? OR contributor_name = ?)',
                                        contributor_params[:resource_id],
                                        contrib_name,
                                        "#{contrib_name}*")&.last
      end
      if contributor.present?
        if contributor.award_number.blank? || contributor.award_description.blank? || contributor.award_title.blank?
          contributor.award_number = contributor_params[:award_number]
          contributor.award_description = contributor_params[:award_description].squish if contributor_params[:award_description].present?
          contributor.award_title = contributor_params[:award_title].squish if contributor_params[:award_title].present?
        else
          contributor.funder_order = contributor_params[:funder_order]
        end
      else
        contributor = Contributor.new(contributor_params)
      end
      contributor
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

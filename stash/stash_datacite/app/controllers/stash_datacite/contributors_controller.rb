require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class ContributorsController < ApplicationController
    before_action :set_contributor, only: %i[update delete]
    before_action :ajax_require_modifiable, only: %i[update create delete]

    # GET /contributors/new
    def new
      Rails.logger.info("----------- contrib_new")
      @contributor = Contributor.new(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    # POST /contributors
    def create
      Rails.logger.info("----------- contrib_create")
      @contributor = Contributor.new(contributor_params)
      process_contributor
      respond_to do |format|
        if @contributor.save
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /contributors/1
    def update
      respond_to do |format|
        if @contributor.update(contributor_params)
          process_contributor
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
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
        format.js
      end
    end

    # GET /contributors/autocomplete?term={query_term}
    def autocomplete
      partial_term = params['term']
      if partial_term.blank?
        render json: nil
      else
        # clean the partial_term of unwanted characters so it doesn't cause errors when calling the CrossRef API
        partial_term.gsub!(%r{[\/\-\\\(\)~!@%&"\[\]\^\:]}, ' ')
        response = HTTParty.get("https://api.crossref.org/funders",
                                query: { 'query': partial_term },
                                headers: { 'Content-Type' => 'application/json' })
        result_list = response.parsed_response["message"]["items"]
        render json: bubble_up_exact_matches(result_list: result_list, term: partial_term)
        #render json: response.body
      end
    end

    private


    def process_contributor
      return nil unless @contributor.present?

      args = contributor_params
      Rails.logger.info("-------------- proc_contrib +======= #{args} ")
      
      if args['name_identifier_id'].present?
        Rails.logger.info("------------ proc_contrib FOUND ID +======= ")
        # init with the contrib name as-is
      else
        Rails.logger.info("------------- proc_contrib NO ID +======= ")
        # init with contrib name getting an asterisk
        @contributor.contributor_name = "#{ args['contributor_name']}*"
      end

      Rails.logger.info("----- contrip is now #{@contributor.to_json}")
      @contributor.save
    end
    
    # Re-order the affiliations list to prioritize exact matches at the beginning of the string, then
    # exact matches within the string, otherwise leaving the order unchanged
    def bubble_up_exact_matches(result_list:, term:)
      matches_at_beginning = []
      matches_within = []
      other_items = []
      match_term = term.downcase
      result_list.each do |result_item|
        name = result_item["name"].downcase
        if name.start_with?(match_term)
          matches_at_beginning << result_item
        elsif name.include?(match_term)
          matches_within << result_item
        else
          other_items << result_item
        end
      end
      matches_at_beginning + matches_within + other_items
    end

    
    def resource
      @resource ||= (params[:contributor] ? StashEngine::Resource.find(contributor_params[:resource_id]) : @contributor.resource)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_contributor
      return if params[:id] == 'new'
      @contributor = Contributor.find((params[:contributor] ? contributor_params[:id] : params[:id]))
      return ajax_blocked unless resource.id == @contributor.resource_id
    end

    # Only allow a trusted parameter "white list" through.
    def contributor_params
      params.require(:contributor).permit(:id, :contributor_name, :contributor_type, :name_identifier_id,
                                          :affiliation_id, :award_number, :resource_id)
    end
  end
end

require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class AffiliationsController < ApplicationController
    # GET /affiliations/autocomplete
    def autocomplete
      unless params[:term].blank?
        @affiliations = Affiliation.where('long_name LIKE ? OR short_name LIKE ? OR abbreviation LIKE ?',
                                          "%#{params[:term]}%", "%#{params[:term]}%", "%#{params[:term]}%")
      end
      list = map_affiliation_for_autocomplete(@affiliations)
      render json: list
    end

    # GET /affiliations/new
    def new
      @affiliation = Affiliation.new
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_affiliation
      @affiliation = Affiliation.find(affiliation_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def affiliation_params
      params.require(:affiliation).permit(:id, :short_name, :long_name, :abbreviation, :campus, :logo, :url, :url_text)
    end

    def map_affiliation_for_autocomplete(affiliations)
      # This is a bit tricky since we want to prefer short names if they are set (ie defined manually in database),
      # however new user-entered items go into long name.
      affiliations.map { |u| Hash[id: u.id, long_name: (u.short_name.blank? ? u.long_name : u.short_name)] }
    end
  end
end

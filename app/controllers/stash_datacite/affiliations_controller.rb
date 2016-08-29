require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class AffiliationsController < ApplicationController
    # GET /affiliations/autocomplete
    def autocomplete
      @affiliations = Affiliation.where('long_name LIKE ? OR short_name LIKE ? OR abbreviation LIKE?',
                                        "%#{params[:term]}%", "%#{params[:term]}%", "%#{params[:term]}%") unless
                                      params[:term].blank?
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
      affiliations.map { |u| Hash[id: u.id, long_name: u.long_name] }
    end
  end
end

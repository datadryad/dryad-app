require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class AffliationsController < ApplicationController
    # GET /affliations/autocomplete
    def autocomplete
      @affliations = Affliation.where('long_name LIKE ? OR short_name LIKE ? OR abbreviation LIKE?',
                                      "%#{params[:term]}%", "%#{params[:term]}%", "%#{params[:term]}%") unless
                                      params[:term].blank?
      list = map_affliation_for_autocomplete(@affliations)
      render json: list
    end

    # GET /affliations/new
    def new
      @affliation = Affliation.new
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_affliation
      @affliation = Affliation.find(affliation_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def affliation_params
      params.require(:affliation).permit(:id, :short_name, :long_name, :abbreviation, :campus, :logo, :url, :url_text)
    end

    def map_affliation_for_autocomplete(affliations)
      affliations.map { |u| Hash[id: u.id, long_name: u.long_name] }
    end
  end
end

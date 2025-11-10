require 'http'
module StashDatacite
  class AwardsController < ApplicationController
    respond_to :json

    # GET /awards/autocomplete?query={query_term}
    def autocomplete
      if params[:name_identifier_id].blank? || params[:award_number].blank?
        return render json: {success: false, error: 'Must select an organization and award number'}
      end

      contrib = StashDatacite::Contributor.new(
        name_identifier_id: params[:name_identifier_id],
        award_number: params[:award_number]
      )

      awards = []
      awards = AwardMetadataService.new(contrib).search if contrib.api_integration_key

      render json: {success: true, awards: }
    end
  end
end

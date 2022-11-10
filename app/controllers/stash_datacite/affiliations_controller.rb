require 'stash_datacite/application_controller'

module StashDatacite
  class AffiliationsController < ApplicationController

    # GET /affiliations/autocomplete
    def autocomplete
      partial_term = params['query']
      if partial_term.blank?
        render json: nil
      else
        @affiliations = StashEngine::RorOrg.find_by_ror_name(partial_term)
        render json: @affiliations
      end
    end

  end
end

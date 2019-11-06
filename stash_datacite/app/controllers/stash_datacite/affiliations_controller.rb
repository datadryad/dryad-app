require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class AffiliationsController < ApplicationController

    include Stash::Organization

    # GET /affiliations/autocomplete
    def autocomplete
      @affiliations = Stash::Organization::Ror.find_by_ror_name(params['term']) unless params['term'].blank?
      list = map_affiliation_for_autocomplete(@affiliations)
      render json: list
    end

    private

    def map_affiliation_for_autocomplete(affiliations)
      # This is a bit tricky since we want to prefer short names if they are set (ie defined manually in database),
      # however new user-entered items go into long name.
      return [] unless affiliations.is_a?(Array)
      affiliations.map { |u| { id: u[:id], long_name: u[:name] } }
    end

  end
end

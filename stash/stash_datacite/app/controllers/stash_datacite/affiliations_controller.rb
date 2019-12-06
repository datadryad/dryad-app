require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class AffiliationsController < ApplicationController

    include Stash::Organization

    # GET /affiliations/autocomplete
    def autocomplete
      partial_term = params['term']
      return if partial_term.blank?
      # clean the partial_term of unwanted characters so it doesn't cause errors when calling the ROR API
      partial_term.gsub!(%r{[\/\-\\\(\)~!@%&"\[\]\^\:]}, ' ')
      logger.debug("searching affiliations for #{partial_term}")
      @affiliations = Stash::Organization::Ror.find_by_ror_name(partial_term)
      list = map_affiliation_for_autocomplete(bubble_up_exact_matches(affil_list: @affiliations, term: partial_term))
      render json: list
    end

    private

    def map_affiliation_for_autocomplete(affiliations)
      # This is a bit tricky since we want to prefer short names if they are set (ie defined manually in database),
      # however new user-entered items go into long name.
      return [] unless affiliations.is_a?(Array)
      affiliations.map { |u| { id: u[:id], long_name: u[:name] } }
    end

    # Re-order the affiliations list to prioritize exact matches at the beginning of the string, then
    # exact matches within the string, otherwise leaving the order unchanged
    def bubble_up_exact_matches(affil_list:, term:)
      matches_at_beginning = []
      matches_within = []
      other_items = []
      match_term = term.downcase
      affil_list.each do |affil_item|
        logger.debug("affil_item #{affil_item}")
        name = affil_item[:name].downcase
        if name.start_with?(match_term)
          matches_at_beginning << affil_item
        elsif name.include?(match_term)
          matches_within << affil_item
        else
          other_items << affil_item
        end
      end
      matches_at_beginning + matches_within + other_items
    end

  end
end

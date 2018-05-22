require 'rest-client'
require 'json'

module Stash
  module EventData
    class Citations
      include Stash::EventData

      DOMAIN = 'https://query.eventdata.crossref.org'
      EMAIL = 'scott.fisher@ucop.edu'
      DATACITE_INCLUDE = %w[is_cited_by is_supplement_to is_referenced_by is_compiled_by is_source_of is_required_by]
      CROSSREF_INCLUDE = %w[cites is_supplemented_by compiles requires references]


      def initialize(doi:)
        @doi = doi
        @doi = doi[4..-1] if doi.downcase.start_with?('doi:')
        @domain = DOMAIN
        @email = EMAIL
      end

      # zoiks, the API seems sketchy as hell, sometimes 500 error, sometimes 200.
      # response.code == 200
      # response.headers -- includes :content_type=>"application/json;charset=UTF-8"

      # can test with '10.5061/dryad.n81g1'
      def datacite_query
        generic_query(filters: "source:datacite,subj-id:#{@doi}")
        # to get the actual citation link you'd use obj_id because this is the subject
      end

      # can test with '10.13140/RG.2.1.1350.3122'
      def crossref_query
        generic_query(filters: "source:crossref,obj-id:#{@doi}")
        # to get the actual citation link for this DOI you'd use subj_id doi because this is the object
      end
    end
  end
end
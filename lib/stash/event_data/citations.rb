require 'http'
require 'json'
require 'cgi'

module Stash
  module EventData
    class Citations
      include Stash::EventData

      attr_reader :doi

      # This domain they say is what I should use, but it returns blank strings and no json
      # BASE_URL = 'https://api.test.datacite.org/events'.freeze
      BASE_URL = 'https://api.datacite.org/events'.freeze
      DATACITE_URL = 'https://doi.org/'.freeze

      OTHERS_CITING_ME = %w[cites describes is-supplemented-by references compiles reviews requires has-metadata documents
                            is-source-of].freeze
      ME_CLAIMING_CITATION = %w[is-cited-by is-supplement-to is-described-by is-metadata-for is-referenced-by
                                is-documented-by is-compiled-by is-reviewed-by is-derived-from is-required-by].freeze

      def initialize(doi:)
        @doi = doi&.downcase # had lots of problems from DataCite event data with an upcase and DOIs are supposed to be case insensitive
        @doi = doi[4..] if doi.start_with?('doi:')
        @base_url = BASE_URL
        @email = APP_CONFIG&.contact_email&.first
      end

      # response.headers -- includes :content_type=>"application/json;charset=UTF-8"
      def results
        params = { 'page[size]': 10_000 }
        result1 = generic_query(url: @base_url,
                                params: params.merge('obj-id': "#{DATACITE_URL}#{@doi}", 'relation-type-id': OTHERS_CITING_ME.join(',')))
        array1 = result1['data'].map { |i| i['attributes']['subj-id'] }

        result2 = generic_query(url: @base_url,
                                params: params.merge('subj-id': "#{DATACITE_URL}#{@doi}", 'relation-type-id': ME_CLAIMING_CITATION.join(',')))
        array2 = result2['data'].map { |i| i['attributes']['obj-id'] }

        (array1 | array2) # returns the union of two sets, which deduplicates identical items, even if in the same original array
      rescue RestClient::ExceptionWithResponse => e
        logger.error("#{Time.new.utc} Could not get citations from DataCite for event data obj-id: #{DATACITE_URL}#{@doi}")
        logger.error("#{Time.new.utc} #{e}")
        []
      end
    end
  end
end

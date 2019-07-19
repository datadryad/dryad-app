require 'rest-client'
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
      EMAIL = 'scott.fisher@ucop.edu'.freeze
      DATACITE_URL = 'https://doi.org/'

      OTHERS_CITING_ME = %w[cites describes references documents is-supplemented-by]
      ME_CLAIMING_CITATION = %w[is-cited-by is-described-by is-referenced-by is-documented-by is-supplement-to]
      # We are not currently using the other way of looking up, but might have to if searching for subjects with this object doesn't work

      def initialize(doi:)
        @doi = doi
        @doi = doi[4..-1] if doi.downcase.start_with?('doi:')
        @base_url = BASE_URL
        @email = EMAIL
      end

      # response.headers -- includes :content_type=>"application/json;charset=UTF-8"
      def results
        params = {'obj-id': "#{DATACITE_URL}#{@doi}", 'relation-type-id': OTHERS_CITING_ME.join(','), 'page[size]': 10_000}
        res = generic_query(params: params)
        res['data'].map{|i| i['attributes']['subj-id']}.uniq

        # I think I need to flip this query, also and do ME_CLAIMING_CITATION and subj-id.
      rescue RestClient::ExceptionWithResponse => err
        logger.error("#{Time.new} Could not get citations from DataCite for event data obj-id: #{DATACITE_URL}#{@doi}")
        logger.error("#{Time.new} #{err}")
        []
      end
    end
  end
end

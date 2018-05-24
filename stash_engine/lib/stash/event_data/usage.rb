require 'rest-client'
require 'json'
require 'cgi'

module Stash
  module EventData
    class Usage
      include Stash::EventData

      BASE_URL = 'https://api.test.datacite.org/events'.freeze
      # BASE_URL = 'https://api.datacite.org/events'.freeze
      EMAIL = 'scott.fisher@ucop.edu'.freeze

      def initialize(doi:)
        @doi = doi
        @doi = doi[4..-1] if doi.downcase.start_with?('doi:')
        @base_url = BASE_URL
        @email = EMAIL
        @stats = nil
      end

      def stats
        @stats ||= query
      end

      # try this doi, at least on test 10.7291/d1q94r
      # can't set large page sizes so have to keep following ['links']['next'] until no more
      def query # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        data = []

        query_result = generic_query(params: { 'source-id': 'datacite-usage', 'obj-id': @doi })
        data += query_result['data'] if query_result['data']

        while query_result['links']['next']
          query_result = make_reliable { RestClient.get query_result['links']['next'] }
          query_result = JSON.parse(query_result)
          data += query_result['data'] if query_result['data']
        end

        return data
      rescue RestClient::ExceptionWithResponse => err
        logger.error("#{Time.new} Could not get response from DataCite event data source-id=datacite-usage&doi=#{CGI.escape(@doi)}")
        logger.error("#{Time.new} #{err}")
        return []
      end

    end
  end
end

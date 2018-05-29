require 'rest-client'
require 'json'
require 'cgi'

module Stash
  module EventData
    class Usage
      include Stash::EventData

      # BASE_URL = 'https://api.test.datacite.org/events'.freeze
      BASE_URL = 'https://api.datacite.org/events'.freeze
      EMAIL = 'scott.fisher@ucop.edu'.freeze
      UNIQUE_INVESTIGATIONS = %w[unique-dataset-investigations-regular unique-dataset-investigations-machine].freeze
      UNIQUE_REQUESTS = %w[unique-dataset-requests-regular unique-dataset-requests-machine].freeze

      def initialize(doi:)
        @doi = doi
        @doi = doi[4..-1] if doi.downcase.start_with?('doi:')
        @base_url = BASE_URL
        @email = EMAIL
        @stats = nil
      end

      # types of stats
      # total-dataset-investigations-regular
      # total-dataset-investigations-machine
      # total-dataset-requests-regular
      # total-dataset-requests-machine
      # unique-dataset-investigations-regular
      # unique-dataset-investigations-machine
      # unique-dataset-requests-regular
      # unique-dataset-requests-machine

      def stats
        @stats ||= query
      end

      def unique_dataset_investigations_count
        stats.inject(0) do |sum, item|
          sum + (UNIQUE_INVESTIGATIONS.include?(item['attributes']['relation-type-id']) ? item['attributes']['total'] : 0)
        end
      end

      def unique_dataset_requests_count
        stats.inject(0) do |sum, item|
          sum + (UNIQUE_REQUESTS.include?(item['attributes']['relation-type-id']) ? item['attributes']['total'] : 0)
        end
      end

      # try this doi, at least on test 10.7291/d1q94r
      # or how about this one? doi:10.7272/Q6Z60KZD
      # or this one has machine hits, I think.  doi:10.6086/D1H59V

      # can't set large page sizes so have to keep following ['links']['next'] until no more to follow
      # and they currently don't allow us to query totals
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

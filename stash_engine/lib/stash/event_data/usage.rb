require 'rest-client'
require 'json'
require 'cgi'

module Stash
  module EventData
    class Usage
      include Stash::EventData

      attr_reader :doi

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
          if UNIQUE_INVESTIGATIONS.include?(item['id'])
            sum + item['year-months'].inject(0) { |sum2, x| sum2 + x['sum'] }.to_i
          else
            sum
          end
        end
      end

      def unique_dataset_requests_count
        stats.inject(0) do |sum, item|
          if UNIQUE_REQUESTS.include?(item['id'])
            sum + item['year-months'].inject(0) { |sum2, x| sum2 + x['sum'] }.to_i
          else
            sum
          end
        end
      end

      def query
        query_result = generic_query(params:
          { 'source-id' => 'datacite-usage', 'doi' => @doi, 'page[size]' => 0,
            'relation-type-id' => (UNIQUE_INVESTIGATIONS + UNIQUE_REQUESTS).join(',') })

        query_result['meta']['relation-types'] || []
      rescue RestClient::ExceptionWithResponse => err
        logger.error('DataCite event-data error')
        logger.error("#{Time.new} Could not get response from DataCite event data source-id=datacite-usage&doi=#{CGI.escape(@doi)}")
        logger.error("#{Time.new} #{err}")
        []
      end

      # try this doi, at least on test 10.7291/d1q94r
      # or how about this one? doi:10.7272/Q6Z60KZD
      # or this one has machine hits, I think.  doi:10.6086/D1H59V

      # can't set large page sizes so have to keep following ['links']['next'] until no more to follow
      # and they currently don't allow us to query totals

      # this is the old query, going through pages, they changed their api
      def old_query
        data = []

        query_result = generic_query(params: { 'source-id': 'datacite-usage', 'doi': @doi })
        data += query_result['data'] if query_result['data']

        while query_result['links']['next']
          query_result = make_reliable { RestClient.get query_result['links']['next'] }
          query_result = JSON.parse(query_result)
          data += query_result['data'] if query_result['data']
        end

        data
      rescue RestClient::ExceptionWithResponse => err
        logger.error("#{Time.new} Could not get response from DataCite event data source-id=datacite-usage&doi=#{CGI.escape(@doi)}")
        logger.error("#{Time.new} #{err}")
        []
      end

    end
  end
end

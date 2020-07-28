require 'json'
require 'cgi'

# some fun datasets to test: doi:10.5061/dryad.234, 10.7272/Q6BG2KWF, 10.5061/dryad.1k84r, 10.5061/dryad.m93f6, 10.7272/Q6H41PB7,
# 10.5061/dryad.2343k, 10.5061/dryad.070jc, 10.5061/dryad.8j60q, 10.5061/dryad.kd00n, 10.5061/dryad.6rd6f

module Stash
  module EventData
    class Usage
      include Stash::EventData

      attr_reader :doi

      # BASE_URL = 'https://api.test.datacite.org/events'.freeze
      BASE_URL = 'https://api.datacite.org/events'.freeze
      HEARTBEAT_URL = 'https://api.datacite.org/heartbeat'.freeze
      EMAIL = 'scott.fisher@ucop.edu'.freeze
      UNIQUE_INVESTIGATIONS = %w[unique-dataset-investigations-regular unique-dataset-investigations-machine].freeze
      UNIQUE_REQUESTS = %w[unique-dataset-requests-regular unique-dataset-requests-machine].freeze

      def initialize(doi:)
        @doi = doi
        @doi = doi[4..] if doi.downcase.start_with?('doi:')
        @base_url = BASE_URL
        @email = EMAIL
        @stats = nil
      end

      def self.ping
        HTTP.get(HEARTBEAT_URL)
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
          if UNIQUE_INVESTIGATIONS.include?(item[:attributes]['relation-type-id'])
            sum + item[:attributes][:total]
          else
            sum
          end
        end
      end

      def unique_dataset_requests_count
        stats.inject(0) do |sum, item|
          if UNIQUE_REQUESTS.include?(item[:attributes]['relation-type-id'])
            sum + item[:attributes][:total]
          else
            sum
          end
        end
      end

      def query
        data_results = []

        query_result = generic_query(url: @base_url, params:
          { 'source-id' => 'datacite-usage', 'doi' => @doi, 'page[size]' => 500,
            'relation-type-id' => (UNIQUE_INVESTIGATIONS + UNIQUE_REQUESTS).join(',') })

        data_results.concat(query_result[:data])

        # if this doesn't contain full set of results, then keep going to the next page and adding them
        while query_result[:links][:next].present? do
          query_result = generic_query(url: query_result[:links][:next])
          data_results.concat(query_result[:data])
        end

        # it looks like we actually want ['data']['attributes'] -- relation-type-id gives type,
        # total -- number, occurred-at is month
        data_results || []
      rescue Stash::EventData::QueryFailure => e
        logger.error('DataCite event-data error')
        logger.error("#{Time.new.utc} Could not get response from DataCite event data source-id=datacite-usage&doi=#{CGI.escape(@doi)}")
        logger.error("#{Time.new.utc} #{e}\n#{e.backtrace.join("\n")}")
        []
      end
    end
  end
end

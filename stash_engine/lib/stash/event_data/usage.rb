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
      HEARTBEAT_URL = 'https://api.datacite.org/heartbeat'.freeze
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

      def self.ping
        RestClient.get HEARTBEAT_URL
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
            sum + item['count'].to_i
          else
            sum
          end
        end
      end

      def unique_dataset_requests_count
        stats.inject(0) do |sum, item|
          if UNIQUE_REQUESTS.include?(item['id'])
            sum + item['count'].to_i
          else
            sum
          end
        end
      end

      def query
        query_result = generic_query(params:
          { 'source-id' => 'datacite-usage', 'doi' => @doi, 'page[size]' => 0, 'rows' => nil,
            'relation-type-id' => (UNIQUE_INVESTIGATIONS + UNIQUE_REQUESTS).join(',') })
        query_result['meta']['relation-types'] || []
      rescue RestClient::ExceptionWithResponse => err
        logger.error('DataCite event-data error')
        logger.error("#{Time.new.utc} Could not get response from DataCite event data source-id=datacite-usage&doi=#{CGI.escape(@doi)}")
        logger.error("#{Time.new.utc} #{err}")
        []
      end
    end
  end
end

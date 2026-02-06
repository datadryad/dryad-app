require 'json'
require 'cgi'

# some fun datasets to test: doi:10.5061/dryad.234, 10.7272/Q6BG2KWF, 10.5061/dryad.1k84r, 10.5061/dryad.m93f6, 10.7272/Q6H41PB7,
# 10.5061/dryad.2343k, 10.5061/dryad.070jc, 10.5061/dryad.8j60q, 10.5061/dryad.kd00n, 10.5061/dryad.6rd6f

module Datacite
  class EventData
    attr_reader :doi

    UNIQUE_INVESTIGATIONS = %w[unique-dataset-investigations-regular unique-dataset-investigations-machine].freeze
    UNIQUE_REQUESTS = %w[unique-dataset-requests-regular unique-dataset-requests-machine].freeze

    def initialize(doi:)
      @doi = doi.downcase.start_with?('doi:') ? doi[4..] : doi
      @stats = nil
    end

    def self.ping
      Integrations::Datacite.new.ping('/heartbeat')
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
        if UNIQUE_INVESTIGATIONS.include?(item['attributes']['relation-type-id'])
          sum + item['attributes']['total']
        else
          sum
        end
      end
    end

    def unique_dataset_requests_count
      stats.inject(0) do |sum, item|
        if UNIQUE_REQUESTS.include?(item['attributes']['relation-type-id'])
          sum + item['attributes']['total']
        else
          sum
        end
      end
    end

    def query
      results = []

      params = { doi: @doi, 'relation-type-id': (UNIQUE_INVESTIGATIONS + UNIQUE_REQUESTS).join(','), 'page[size]': 500 }
      query_result = Integrations::Datacite.new.query('/events', params)

      results.concat(query_result['data'])

      # if this doesn't contain full set of results, then keep going to the next page and adding them
      while query_result.dig('links', 'next').present?
        params['page[number]'] = query_result.dig('meta', 'page').to_i + 1
        query_result = Integrations::Datacite.new.query('/events', params)
        results.concat(query_result['data'])
      end

      results
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET => e
      Rails.logger.error('DataCite event-data error')
      Rails.logger.error("#{Time.new.utc} Could not get response from DataCite event data #{params}")
      Rails.logger.error("#{Time.new.utc} #{e}\n#{e.full_message}")
      []
    end
  end
end

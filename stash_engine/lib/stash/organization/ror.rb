require 'httparty'

module Stash

  module Organization

    module Ror
      # Module that facilitates communications with the ROR API:
      #    https://github.com/ror-community/ror-api/blob/master/api_documentation.md
      URI = 'https://api.ror.org/organizations'.freeze
      HEADERS = { 'Content-Type': 'application/json' }.freeze
      ROR_MAX_RESULTS = 20.0
      MAX_PAGES = 10

      # Search the ROR API for the given string. This will search name, acronyms, aliases, etc.
      # @return an Array of Hashes { id: 'https://ror.org/12345', name: 'Sample University' }
      # The ROR limit appears to be 40 results (even with paging :/)
      def find_by_ror_name(query)
        resp = query_ror(URI, { 'query.names': query }, HEADERS)
        results = process_pages(resp, query) if resp.parsed_response.present? &&
          resp.parsed_response['items'].present?
        results.flatten.uniq.sort_by { |a| a[:name] }
      end

      # Search the ROR API for a specific organization.
      # @return a Stash::Organization::Ror::Organization object or nil
      def find_by_ror_id(ror_id)
        resp = HTTParty.get("#{URI}/#{ror_id}", headers: HEADERS)
        return nil if resp.parsed_response.blank? ||
                      resp.parsed_response['id'].blank? ||
                      resp.parsed_response['name'].blank?
        Organization.new(resp.parsed_response)
      end

      class Organization

        attr_accessor :country

        # rubocop:disable Metrics/CyclomaticComplexity
        def initialize(params)
          @id = params['id']
          @name = params['name']
          @country = params['country'] || { 'code': nil, 'name': nil }
          @types = params['types'] || []
          @acronyms = params['acronyms'] || []
          @aliases = params['aliases'] || []
          @links = params['links'] || []
          @labels = params['labels'] || []
          @external_ids = params['external_ids'] || []
        end
        # rubocop:enable Metrics/CyclomaticComplexity

      end

      private

      def process_pages(resp, query)
        results = ror_results_to_hash(resp)
        # Detemine if there are multipe pages of results
        pages = (resp.parsed_response['number_of_results'] / ROR_MAX_RESULTS).to_f.ceil
        return results unless pages > 1
        # Gather the results from the additional page (only up to the max)
        (2..(pages > MAX_PAGES ? MAX_PAGES : pages)).each do |page|
          paged_resp = query_ror(URI, { 'query.names': query, page: page }, HEADERS)
          results += ror_results_to_hash(paged_resp) if paged_resp.parsed_response.is_a?(Hash) &&
                                                        paged_resp.parsed_response['items'].present?
        end
        results
      end

      def query_ror(uri, query, headers)
        resp = HTTParty.get(uri, query: query, headers: headers)
        # If we received anything but a 200 then log an error and return an empty array
        log.error "Unable to connect to ROR #{URI}?#{query}: status: #{resp.code}" if resp.code != 200
        # Return an empty array if the response did not have any results
        return nil if resp.code != 200 || resp.blank?
        resp
      end

      def ror_results_to_hash(response)
        results = []
        response.parsed_response['items'].each do |item|
          next unless item['id'].present? && item['name'].present?
          results << { id: item['id'], name: item['name'] }
        end
        results
      end

    end

  end

end

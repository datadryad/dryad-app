require 'httparty'

module Stash
  module Aws
    class S3
      # Module that facilitates communications with AWS S3

      def initialize(params)
        @id = params['id']
        @name = params['name']
        @country = params['country'] || { 'country_code': nil, 'country_name': nil }
        @acronyms = params['acronyms'] || []
      end

      # Ping the ROR API to determine if it is online
      def self.ping
        HTTParty.get(HEARTBEAT_URI).code == 200
      end

      # Search the ROR API for the given string. This will search name, acronyms, aliases, etc.
      # @return an Array of Hashes { id: 'https://ror.org/12345', name: 'Sample University' }
      # The ROR limit appears to be 40 results (even with paging :/)
      def self.find_by_ror_name(query)
        resp = query_ror(URI, { 'query': query }, HEADERS)
        results = process_pages(resp, query) if resp.parsed_response.present? && resp.parsed_response['items'].present?
        results.present? ? results.flatten.uniq : []
      rescue HTTParty::Error, SocketError => e
        raise RorError, "Unable to connect to the ROR API for `find_by_ror_name`: #{e.message}"
      end

      # Search ROR and return the first match for the given name
      # @return a Stash::Organization::Ror::Organization object or nil
      def self.find_first_by_ror_name(ror_name)
        resp = query_ror(URI, { 'query': ror_name }, HEADERS)
        return nil if resp.parsed_response.blank? || resp.parsed_response['items'].blank?

        result = resp.parsed_response['items'].first
        return nil if result['id'].blank? || result['name'].blank?

        new(result)
      rescue HTTParty::Error, SocketError => e
        raise RorError, "Unable to connect to the ROR API for `find_first_by_ror_name`: #{e.message}"
      end

      # Search the ROR API for a specific organization.
      # @return a Stash::Organization::Ror::Organization object or nil
      def self.find_by_ror_id(ror_id)
        resp = HTTParty.get("#{URI}/#{ror_id}", headers: HEADERS)
        return nil if resp.parsed_response.blank? ||
                      resp.parsed_response['id'].blank? ||
                      resp.parsed_response['name'].blank?

        new(resp.parsed_response)
      rescue HTTParty::Error, SocketError => e
        raise "Unable to connect to the ROR API for `find_by_ror_id`: #{e.message}"
      end

      # Search the ROR API for a specific organization.
      # @return a Stash::Organization::Ror::Organization object or nil
      def self.find_by_isni_id(isni_id)
        isni_id = standardize_isni_format(isni_id)
        resp = query_ror(URI, { 'query': isni_id }, HEADERS)
        return nil if resp.parsed_response.blank? ||
                      resp.parsed_response['number_of_results'] == 0 ||
                      resp.parsed_response['items'].blank?

        new(resp.parsed_response['items'][0])
      rescue HTTParty::Error, SocketError => e
        raise "Unable to connect to the ROR API for `find_by_isni_id`: #{e.message}"
      end

      class << self
        private

        def process_pages(resp, query)
          results = ror_results_to_hash(resp)
          num_of_results = resp.parsed_response['number_of_results'].to_i
          # return [] unless num_of_results.to_i.is_a?(Integer)
          # Detemine if there are multiple pages of results
          pages = (num_of_results / ROR_MAX_RESULTS).to_f.ceil
          return results unless pages > 1

          # Gather the results from the additional page (only up to the max)
          (2..(pages > MAX_PAGES ? MAX_PAGES : pages)).each do |page|
            paged_resp = query_ror(URI, { 'query.names': query, page: page }, HEADERS)
            results += ror_results_to_hash(paged_resp) if paged_resp.parsed_response.is_a?(Hash) &&
                                                          paged_resp.parsed_response['items'].present?
          end
          results || []
        end

        def query_ror(uri, query, headers)
          resp = HTTParty.get(uri, query: query, headers: headers, debug_output: $stdout)
          # If we received anything but a 200 then log an error and return an empty array
          raise RorError, "Unable to connect to ROR #{URI}?#{query}: status: #{resp.code}" if resp.code != 200
          # Return an empty array if the response did not have any results
          return nil if resp.code != 200 || resp.blank?

          resp
        end

        def ror_results_to_hash(response)
          results = []
          return results unless response.parsed_response['items'].is_a?(Array)

          response.parsed_response['items'].each do |item|
            next unless item['id'].present? && item['name'].present?

            results << { id: item['id'], name: item['name'] }
          end
          results
        end

        def standardize_isni_format(isni_id)
          # Remove standardized prefix if it exists
          isni_id.match(%r{http://www.isni.org/isni/(.*)/}) do |m|
            isni_id = m[1]
          end
          isni_id.match(/ISNI?:(.*)/) do |m|
            isni_id = m[1]
          end
          # If it has the digits with embedded spaces, keep it
          return isni_id if isni_id =~ /\d{4} \d{4} \d{4} \d{3,4}X?/

          # If it has no spaces, add them
          isni_id.match(/(\d{4})(\d{4})(\d{4})(\d{3,4}X?)/) do |m|
            return "#{m[1]} #{m[2]} #{m[3]} #{m[4]}"
          end
          # Otherwise, throw an error
          raise "Unexpected structure of ISNI: #{isni_id}; use either 16 digits or 4 sets of 4 digits with spaces between."
        end

      end

    end

  end

end

require 'http'
require 'byebug'
require 'stash/download'

module Stash
  module ZenodoReplicate

    class ZenodoError < StandardError; end
    class RetryError < StandardError; end

    module ZenodoConnection

      SLEEP_TIME = 15
      RETRY_LIMIT = 20



      # checks that can access API with token and return boolean
      def self.validate_access
        standard_request(:get, "#{base_url}/api/deposit/depositions")
        true
      rescue ZenodoError
        false
      end

      # rubocop:disable Metrics/AbcSize
      def self.standard_request(method, url, **args)
        retries = 0

        begin
          resp = nil
          http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
            .timeout(connect: 30, read: 60).timeout(6.hours.to_i).follow(max_hops: 10)

          my_params = { access_token: APP_CONFIG[:zenodo][:access_token] }.merge(args.fetch(:params, {}))
          my_headers = { 'Content-Type': 'application/json' }.merge(args.fetch(:headers, {}))
          my_args = args.merge(params: my_params, headers: my_headers)

          r = http.send(method, url, my_args)

          # zenodo returns application/json even with a 204 and no content to parse as application/json
          resp = r.parse if r.headers['content-type'] == 'application/json' && r.code != 204 # 204 is no-content
          resp = resp.with_indifferent_access if resp.class == Hash

          if r.status.code >= 500
            # zenodo's servers are not working correctly, so maybe they will again soon
            raise RetryError, "Zenodo response: #{r.status.code}\n#{resp} for \nhttp.#{method} #{url}\n#{resp}"
          elsif !r.status.success?
            raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp} for \nhttp.#{method} #{url}\n#{resp}" unless r.status.success?
          end

          resp
        rescue HTTP::Error, JSON::ParserError, RetryError => e
          # resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions", json: json)
          # resp = ZC.standard_request(:post, "#{ZC.base_url}/api/deposit/depositions/#{deposition_id}/actions/newversion")
          # ZC.standard_request(:post, @links[:edit])
          # ZC.standard_request(:post, @links[:publish])
          #
          # in zenodo software
          # Streamer does a PUT to zenodo for file, and shouldn't hurt to do it again
          #
          if (retries += 1) <= RETRY_LIMIT
            sleep SLEEP_TIME
            retry
          else
            raise ZenodoError, "Error from HTTP #{method} #{url}\nOriginal error: #{e}\n#{e.backtrace.join("\n")}"
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      def self.special_error_case
        # test this url and see if it exists after a failed POST to resp = ZC.standard_request(:post, "/api/deposit/depositions", json: json)
        # if it exists then just return this from the GET rather than the post because it exists and is time for fun
        # Example returned like https://sandbox.zenodo.org/api/deposit/depositions?q=doi:%2210.7959/dryad.bzkh1894f%22
        "https://sandbox.zenodo.org/api/deposit/depositions?q=doi:\"10.7959/dryad.bzkh1894f\""
      end

      def self.base_url
        APP_CONFIG[:zenodo][:base_url]
      end
    end
  end
end

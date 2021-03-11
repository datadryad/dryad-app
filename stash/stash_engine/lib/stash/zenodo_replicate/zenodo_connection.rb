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
      ZENODO_PADDING_TIME = 2

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
            # zenodo's servers seem to give 504s sometimes
            raise RetryError, "Zenodo response: #{r.status.code}\n#{resp} for \nhttp.#{method} #{url}\n#{resp}"
          elsif !r.status.success?
            # for things like 400 errors that aren't likely to change with a Retry
            raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp} for \nhttp.#{method} #{url}\n#{resp}" unless r.status.success?
          end

          sleep ZENODO_PADDING_TIME # it seems that zenodo might sometimes gives us 504 errors if our requests are too rapid
          resp
        rescue HTTP::Error, JSON::ParserError, RetryError => e
          if (retries += 1) <= RETRY_LIMIT
            sleep SLEEP_TIME
            retry
          else
            raise ZenodoError, "Error from HTTP #{method} #{url}\nOriginal error: #{e}\n#{e.backtrace.join("\n")}"
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      # NOTE: Alex suggested we use a URL like https://sandbox.zenodo.org/api/deposit/depositions?q=doi:%2210.7959/dryad.bzkh1894f%22
      # to do lookups by DOIs to see they exist before proceeding with a retry on a POST request.

      # However, our POST requests are generally for creation of a blank dataset and have never seen problems.
      # We're already tracking DOIs that are submitted (our own DOIs or Zenodo dois for non-data) and have never seen
      # any real problems with duplicate datasets being retried at that request.

      # The only problem we've ever seen is for metadata updates with a PUT request for a dataset like
      # http.put https://sandbox.zenodo.org/api/deposit/depositions/745192 and we got a 400 response code if the DOI
      # already exists in another dataset and problem surfaced only a couple of times out of about 8,000 submissions.
      # I think it is better to understand why these couple may happen and fix manually rather than blindly try to upate
      # some other random dataset that has the same DOI in it and may not be in a good state in other ways besides this
      # one request.

      # So I'm not going to automate this kind of action until we have a better understanding of the real problem in these rare cases.

      def self.base_url
        APP_CONFIG[:zenodo][:base_url]
      end
    end
  end
end

require 'http'
require 'byebug'
require 'stash/download'

module Stash
  module ZenodoReplicate
    module ZenodoConnection

      SLEEP_TIME = 15
      RETRY_LIMIT = 5
      ZENODO_PADDING_TIME = 2

      # checks that can access API with token and return boolean
      def self.validate_access
        standard_request(:get, "#{base_url}/api/deposit/depositions")
        true
      rescue ZenodoError
        false
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def self.standard_request(method, url, **args)
        retries = 0

        # the zenodo copy so we can log all the requests to the database, zd_id is just to enable logging
        zen_copy = (StashEngine::ZenodoCopy.where(id: args[:zc_id]).first if args[:zc_id])
        args.delete(:zc_id)

        # if the caller wants to give a retry_limit, they can.  Useful for file uploads where there is streaming
        retry_limit = args[:retries] || RETRY_LIMIT
        args.delete(:retries)

        begin
          resp = nil
          http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
            .timeout(connect: 30, read: 180, write: 180).follow(max_hops: 10)

          my_params = { access_token: access_token }.merge(args.fetch(:params, {}))
          my_headers = { 'Content-Type': 'application/json' }.merge(args.fetch(:headers, {}))
          my_args = args.merge(params: my_params, headers: my_headers)

          log_to_database(item: "REQUEST: #{method}, #{url}\n   #{my_args&.merge(params: { access_token: 'hidden' })}",
                          zen_copy: zen_copy)
          r = http.send(method, url, my_args)
          log_to_database(item: "RESPONSE: #{r.inspect}", zen_copy: zen_copy)

          # zenodo returns application/json even with a 204 and no content to parse as application/json
          resp = r.parse if r.headers['content-type'] == 'application/json' && r.code != 204 # 204 is no-content
          resp = resp.with_indifferent_access if resp.instance_of?(Hash)

          # zenodo's servers seem to give 504s sometimes
          raise RetryError, "Zenodo response: #{r.status.code}\n#{resp} for \nhttp.#{method} #{url}\n#{resp}" if r.status.code >= 500

          return resp if method.to_sym == :delete && r.status.code == 404 # ignore deleting if it already doesn't exist

          # for things like 400 errors that aren't likely to change with a Retry
          raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp} for \nhttp.#{method} #{url}\n#{resp}" unless r.status.success?

          sleep ZENODO_PADDING_TIME # it seems that zenodo might sometimes gives us 504 errors if our requests are too rapid
          resp
        rescue HTTP::Error, HTTP::ConnectionError, JSON::ParserError, RetryError => e
          log_to_database(item: "ERROR: #{e.full_message}", zen_copy: zen_copy)
          # rubocop, can't do a guard clause with conditional at end like it suggests with more than one line inside an if statement
          # rubocop:disable Style/GuardClause
          if (retries += 1) <= retry_limit
            log_to_database(item: "Error at zenodo, retrying in #{SLEEP_TIME} seconds", zen_copy: zen_copy)
            sleep SLEEP_TIME
            retry
          else
            raise ZenodoError, "Error from HTTP #{method} #{url}\nOriginal error: #{e}\n#{e.full_message}"
          end
          # rubocop:enable Style/GuardClause
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def self.log_to_database(item:, zen_copy:)
        return unless zen_copy

        zen_copy.update(error_info: "#{zen_copy.error_info}\n#{Time.new.utc.iso8601} #{item}\n")
      end

      # NOTE: Alex suggested we use a URL like https://sandbox.zenodo.org/api/deposit/depositions?q=doi:%2210.7959/dryad.bzkh1894f%22
      # to do lookups by DOIs to see they exist before proceeding with a retry on a POST request.

      # However, our POST requests are generally for creation of a blank dataset and have never seen problems.
      # We're already tracking DOIs that are submitted (our own DOIs or Zenodo dois for non-data) and have never seen
      # any real problems with duplicate datasets being retried at that request.

      # The only problem we've ever seen is for metadata updates with a PUT request for a dataset like
      # http.put https://sandbox.zenodo.org/api/deposit/depositions/745192 and we got a 400 response code if the DOI
      # already exists in another dataset and problem surfaced only a couple of times out of about 8,000 submissions.
      # I think it is better to understand why these couple may happen and fix manually rather than blindly try to update
      # some other random dataset that has the same DOI in it and may not be in a good state in other ways besides this
      # one request.

      # So I'm not going to automate this kind of action until we have a better understanding of the real problem in these rare cases.

      def self.base_url
        APP_CONFIG[:zenodo][:base_url]
      end

      def self.access_token
        state = StashEngine::GlobalState.where(key: 'zenodo_api')&.first&.state
        state = state.with_indifferent_access if state.is_a?(Hash)

        return new_access_token if state.nil? || state[:expires_at].blank? || state[:expires_at].to_time < (Time.new + 1.minute)

        state[:access_token]
      end

      # gets access token from api, stores access token to database, and also returns it
      def self.new_access_token
        # example from zenodo has {"access_token": <token>, "expires_in": <time>} and some other stuff
        data = { client_id: APP_CONFIG[:zenodo][:client_id],
                 client_secret: APP_CONFIG[:zenodo][:client_secret],
                 grant_type: 'client_credentials',
                 scope: 'user:email' }

        resp = HTTP.post("#{base_url}/oauth/token", form: data)

        raise ZenodoError, "Received #{resp.status} code from zenodo API" if resp.status > 399

        json = resp.parse
        zen_state = StashEngine::GlobalState.where(key: 'zenodo_api')&.first
        zen_state = StashEngine::GlobalState.create(key: 'zenodo_api') if zen_state.nil?
        zen_state.update(state: { access_token: json['access_token'], expires_at: (Time.new + json['expires_in'].seconds) })

        json['access_token']
      end
    end
  end
end

require 'http'

module Integrations
  class Datacite < Integrations::Base

    def self.http
      HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
        .timeout(connect: 30, read: 60).timeout(60).follow(max_hops: 10)
        .basic_auth(user: APP_CONFIG[:identifier_service][:account], pass: APP_CONFIG[:identifier_service][:password])
    end

    def ping(url)
      HTTP.get("#{api_url}#{url}")
    end

    def query(url, payload = nil)
      get_json("#{api_url}#{url}", payload)
    end

    private

    def api_url
      # APP_CONFIG[:identifier_service][:rest]
      'https://api.datacite.org'
    end

  end
end

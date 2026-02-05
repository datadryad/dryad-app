require 'http'

module Integrations
  class Datacite < Integrations::Base

    def self.http
      HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
        .timeout(connect: 30, read: 60).timeout(60).follow(max_hops: 10)
        .basic_auth(user: APP_CONFIG[:identifier_service][:account], pass: APP_CONFIG[:identifier_service][:password])
    end

  end
end

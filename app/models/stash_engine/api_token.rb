require 'http'

module StashEngine
  class ApiTokenStatusError < StandardError; end

  # A class for allowing access through tokens for our own API
  # Why do this?  We can pass in the token to sn AWS Lambda and then the lambda can access our API
  # It's easier if we make lambda's mostly stateless and limit the amount of code they contain rather making them "fat"
  #
  # Start by creating a blank record in the table (will probably only contain 1 line) and enter the app_id and secret
  # and getting a token should automatically handle getting the token, expiration, etc
  class ApiToken < ApplicationRecord
    self.table_name = 'stash_engine_api_tokens'

    def self.token
      tok = all.first
      return tok.token if tok.expires_at > (Time.new + 30.minutes)

      tok.new_token
      tok.reload
      tok.token
    end

    # check that our test url works for a logged in user
    def self.test_api
      url = Rails.application.routes.url_helpers.test_url

      resp = HTTP.headers('Authorization': "Bearer #{token}").get(url)

      resp.parse
    end

    def new_token
      attempts ||= 1
      url = Rails.application.routes.url_helpers.oauth_token_url # url on current server to get token

      resp = HTTP.post(url,
                       json: { client_id: app_id,
                               client_secret: secret,
                               grant_type: 'client_credentials' })

      raise StashEngine::ApiTokenStatusError, "Received #{resp.status} code from API" if resp.status > 399

      json = resp.parse
      update(token: json['access_token'], expires_at: (Time.new + json['expires_in'].seconds))
    rescue HTTP::Error, HTTP::TimeoutError, StashEngine::ApiTokenStatusError => e
      logger.warn("Http error getting API key: #{e.full_message}")
      sleep 3
      retry if (attempts += 1) < 10

      raise e
    end
  end
end

require 'openssl'
require 'jwt'

module Integrations
  class Github < Integrations::Base
    def query_issue(issue)
      uri = URI.parse("https://api.github.com/repos/datadryad/dryad-product-roadmap/issues/#{issue}")
      headers = {
        'Authorization' => "Bearer #{token}",
        'Accept' => 'application/vnd.github+json'
      }
      get_json(uri, nil, headers)
    end

    private

    def token
      uri = URI.parse("https://api.github.com/app/installations/#{installation}/access_tokens")
      headers = {
        'Authorization' => "Bearer #{js_token}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/vnd.github+json'
      }
      json = post_json(uri, nil, headers)
      json['token']
    end

    def installation
      uri = URI.parse('https://api.github.com/app/installations')
      headers = {
        'Authorization' => "Bearer #{js_token}",
        'Accept' => 'application/vnd.github+json'
      }
      json = get_json(uri, nil, headers)
      json.dig(0, 'id')
    end

    def js_token
      return @js_token if @js_token.present?

      # https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app#example-using-ruby-to-generate-a-jwt
      pem = "-----BEGIN RSA PRIVATE KEY-----\n#{APP_CONFIG[:github][:pem].gsub(' ', "\n")}\n-----END RSA PRIVATE KEY-----\n"
      private_key = OpenSSL::PKey::RSA.new(pem)
      payload = {
        # issued at time, 60 seconds in the past to allow for clock drift
        iat: Time.now.to_i - 60,
        # JWT expiration time (10 minute maximum)
        exp: Time.now.to_i + (10 * 60),
        # GitHub App's client ID
        iss: APP_CONFIG[:github][:client_id].to_s
      }
      @js_token = JWT.encode(payload, private_key, 'RS256')
    end
  end
end

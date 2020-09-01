require 'jwt'

# implementation of https://gist.github.com/slint/54d197ce12757719817b242fbeff0ea3#generating-the-rat
# testing against https://sandbox.zenodo.org/deposit/638092

module Stash
  module ZenodoSoftware
    class RemoteAccessToken

      def initialize(zenodo_config:) # APP_CONFIG.zenodo
        @pat_token = zenodo_config.access_token
        @pat_token_id = 3357
        @base_url = zenodo_config.base_url
      end

      def make_jwt(deposition_id:, filename:)
        payload = {
          sub: {
            deposit_id: deposition_id,
            file: filename,
            access: 'read'
          },
          iat: Time.now.to_i # this is what the docs at https://github.com/jwt/ruby-jwt shows
        }
        headers = { kid: @pat_token_id }

        JWT.encode(payload, @pat_token, 'HS256', headers)
      end

      def magic_url(deposition_id:, filename:)
        rat_token = make_jwt(deposition_id: deposition_id, filename: filename)
        "#{@base_url}/api/deposit/depositions/#{deposition_id}/files/#{ERB::Util.url_encode(filename)}?" \
        "token=#{ERB::Util.url_encode(rat_token)}"
      end
    end
  end
end

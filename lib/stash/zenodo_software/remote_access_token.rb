require 'jwt'
require 'byebug'
require 'http'

# implementation of https://gist.github.com/slint/54d197ce12757719817b242fbeff0ea3#generating-the-rat
# testing against https://sandbox.zenodo.org/deposit/638092

# rat = Stash::ZenodoSoftware::RemoteAccessToken.new(zenodo_config: APP_CONFIG.zenodo)
# url = rat.magic_url(deposition_id: 638092 , filename: 'Screen_Shot_2020-06-10_at_8.00.12_PM.png')

module Stash
  module ZenodoSoftware
    class RemoteAccessToken

      ZC = Stash::ZenodoReplicate::ZenodoConnection

      def initialize(zenodo_config:) # APP_CONFIG.zenodo
        @pat_token = zenodo_config.access_token
        @pat_token_id = zenodo_config.application_id.to_s
        @base_url = zenodo_config.base_url
      end

      def make_jwt(deposition_id:, filename:)
        payload = {
          sub: {
            deposit_id: deposition_id.to_s,
            file: filename,
            access: 'read'
          },
          iat: Time.now.to_i # this is what the docs at https://github.com/jwt/ruby-jwt show
        }
        headers = { kid: @pat_token_id }

        JWT.encode(payload, @pat_token, 'HS256', headers)
      end

      def magic_url(deposition_id:, filename:)
        # Alex said to use bucket url like this instead of the other filename API endpoint, requires extra query
        # to get the bucket from the deposit.
        rat_token = make_jwt(deposition_id: deposition_id.to_s, filename: filename)
        buck_url = get_bucket_url(deposition_id)
        return nil if buck_url.nil?

        "#{buck_url}/#{ERB::Util.url_encode(filename)}?token=#{ERB::Util.url_encode(rat_token)}"
      end

      def get_bucket_url(deposition_id)
        http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
          .timeout(connect: 30, read: 180, write: 180).follow(max_hops: 10)

        resp = http.get("#{@base_url}/api/deposit/depositions/#{deposition_id}",
                        params: { access_token: @pat_token },
                        headers: { 'Content-Type': 'application/json' })

        if resp.try(:status).try(:code) < 400
          resp = resp.parse
          return resp[:links][:bucket]
        end

        nil
      end
    end
  end
end

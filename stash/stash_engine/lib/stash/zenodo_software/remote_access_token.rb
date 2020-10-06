require 'jwt'
require 'byebug'

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
        # I believe Alex said to use url like this instead "#{@resp[:links][:bucket]}/#{ERB::Util.url_encode(filename)}"
        rat_token = make_jwt(deposition_id: deposition_id.to_s, filename: filename)
        "#{get_bucket_url(deposition_id)}/#{ERB::Util.url_encode(filename)}?token=#{ERB::Util.url_encode(rat_token)}"
      end

      def get_bucket_url(deposition_id)
        resp = ZC.standard_request(:get, "#{@base_url}/api/deposit/depositions/#{deposition_id}")
        resp[:links][:bucket]
      end
    end
  end
end

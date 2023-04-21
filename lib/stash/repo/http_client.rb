require 'httpclient'

module Stash
  module Repo

    # a class to handle all the fiddly things we have to do to make a request to  our Merritt Repo so it doesn't barf
    # TODO:  Maybe this should really be Merritt rather than repo class and maybe be moved to stash-merritt
    class HttpClient

      TIMEOUT = 600 # 10 minutes

      attr_accessor :client

      # pass in the tenant so that it can set all the stuff it needs for domains and basic auth, pass in a special cert file if needed
      def initialize(cert_file: nil)
        @client = HTTPClient.new

        # this callback allows following redirects from http to https, otherwise it will not
        @client.redirect_uri_callback = ->(_uri, res) {
          res.header['location'][0]
        }

        # ran into problems like https://github.com/nahi/httpclient/issues/181 so forcing basic auth
        @client.force_basic_auth = true
        @client.set_basic_auth(nil, APP_CONFIG[:repository][:username], APP_CONFIG[:repository][:password])

        # TODO: remove this once Merritt has fixed their certs on their stage server.
        @client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: remove for extra security once Merritt gets real certs
        @client.ssl_config.set_trust_ca(cert_file) if cert_file
        @client.connect_timeout = TIMEOUT
        @client.send_timeout = TIMEOUT
        @client.receive_timeout = TIMEOUT
        @client.keep_alive_timeout = TIMEOUT
      end
    end
  end
end

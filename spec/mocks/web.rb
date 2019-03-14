require 'webmock/rspec'

# Allow connections by default (Solr needs to call out to apache.org on startup)
WebMock.allow_net_connect!

# Module to facilitate the enabling/disabling of WebMock
# Individual tests should stub out their own requests.
# For details, see: https://github.com/bblimke/webmock
#
# For example, in your test use:
#    include Mocks::Web
#
#    before(:all) do
#      disable_net_connect!
#      stub_request(:post, "www.example.com").
#        with(body: /world$/, headers: {"Content-Type" => /image\/.+/}).
#        to_return(body: "abc")
#    end
#
#    after(:all) do
#      enable_net_connect!
#    end
module Mocks

  module Web

    # White list for any connections that we want to allow by default
    WHITE_LIST = %w[
      localhost
      www.apache.org
    ].freeze

    def disable_net_connect!
      WebMock.disable_net_connect!(allow: WHITE_LIST)
    end

    def enable_web_traffic!
      WebMock.allow_net_connect!
    end

  end

end

require 'webmock/rspec'

module WebmockHelper

  # White list for any connections that we want to allow by default
  WHITE_LIST = [
    /localhost/,
    /127\.0\.0\.1/,
    /\/lucene\/solr\//
  ].freeze

  def disable_net_connect!
    WebMock.disable_net_connect!(allow: WHITE_LIST)
  end

  def allow_net_connect!
    WebMock.allow_net_connect!
  end

end

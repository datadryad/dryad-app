require 'spec_helper'
require 'webmock/rspec'

module StashEngine
  describe UrlValidator do
    before(:each) do
      WebMock.disable_net_connect!
    end

    it 'retrieves a url' do
      stub_request(:any, 'http://www.blahstackfood.com')
      uv = UrlValidator.new(url: 'http://www.blahstackfood.com')
      success = uv.validate
      # [ uv.mime_type, uv.size, uv.url, uv.status_code, uv.redirected_to, uv.timed_out?, uv.redirected?, uv.correctly_formatted_url? ]
      expect(success).to eq(true)
      expect(uv.status_code).to eq(200)
    end
  end
end

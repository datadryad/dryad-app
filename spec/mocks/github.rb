module Mocks
  module Github
    def mock_github!
      default = OpenSSL::PKey::RSA.new(2048)
      double = class_double(OpenSSL::PKey::RSA).as_stubbed_const
      allow(double).to receive(:new).and_return(default)
      stub_request(:get, 'https://api.github.com/app/installations')
        .with(
          headers: {
            'Accept' => '*/*',
            'Host' => 'api.github.com',
            'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: [{ id: 0o003 }].to_json)
      stub_request(:post, 'https://api.github.com/app/installations/0003/access_tokens')
        .with(
          headers: {
            'Accept' => '*/*',
            'Host' => 'api.github.com',
            'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: { token: 'ajhafhsjfhsd' }.to_json)
      stub_request(:get, 'https://api.github.com/repos/datadryad/dryad-product-roadmap/issues/1234')
        .with(
          headers: {
            'Accept' => '*/*',
            'Host' => 'api.github.com',
            'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: { title: 'Test github issue', html_url: 'https://github.com/datadryad/dryad-product-roadmap/issues/1234',
                                         assignee: nil, closed_at: nil }.to_json, headers: {})
      stub_request(:get, 'https://api.github.com/repos/datadryad/dryad-product-roadmap/issues/1235')
        .with(
          headers: {
            'Accept' => '*/*',
            'Host' => 'api.github.com',
            'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: { title: 'Another test github issue', html_url: 'https://github.com/datadryad/dryad-product-roadmap/issues/1235',
                                         assignee: nil, closed_at: nil }.to_json, headers: {})
    end
  end
end

module Mocks
  module Github
    def mock_github!
      default = OpenSSL::PKey::RSA.new(2048)
      double = class_double(OpenSSL::PKey::RSA).as_stubbed_const
      allow(double).to receive(:new).and_return(default)
      stub_request(:get, 'https://api.github.com/app/installations').to_return(status: 200, body: [{ id: 3 }].to_json)
      stub_request(:post, 'https://api.github.com/app/installations/3/access_tokens')
        .to_return(status: 200, body: { token: 'ajhafhsjfhsd' }.to_json)
      stub_request(:get, 'https://api.github.com/repos/datadryad/dryad-product-roadmap/issues/1234')
        .to_return(status: 200, body: { title: 'Test github issue', html_url: 'https://github.com/datadryad/dryad-product-roadmap/issues/1234',
                                        assignee: nil, closed_at: nil }.to_json, headers: {})
      stub_request(:get, 'https://api.github.com/repos/datadryad/dryad-product-roadmap/issues/1235')
        .to_return(status: 200, body: { title: 'Another test github issue', html_url: 'https://github.com/datadryad/dryad-product-roadmap/issues/1235',
                                        assignee: nil, closed_at: nil }.to_json, headers: {})
    end
  end
end

module Mocks
  module Github
    def mock_github!
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

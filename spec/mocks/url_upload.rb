module Mocks

  module UrlUpload
    def mock_github_head_request!
      stub_request(:head, 'http://github.com/CDL-Dryad/dryad/raw/master/app/assets/images/favicon.ico')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 200, body: '', headers: {
                     'ETag' => '0983b74561d93c478328fbbae799bbccfe1528e5',
                     'Content-Type' => 'image/vnd.microsoft.icon',
                     'Cache-Control' => 'max-age=300',
                     'Content-Length' => 6318,
                     'Accept-Ranges' => 'bytes'
                   })
    end

    def mock_github_bad_head_request!
      stub_request(:head, 'http://github.com/CDL-Dryad/dryad/raw/master/app/assets/images/favicon.ico')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 404, body: '', headers: {
                     'Cache-Control' => 'max-age=300'
                   })
    end

  end

end

module Mocks

  module UrlUpload
    def mock_github_head_request!
      stub_request(:head, 'http://github.com/datadryad/dryad-app/raw/main/app/assets/images/favicon.ico')
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

    def mock_github_blob_head_request!
      stub_request(:head, 'https://raw.githubusercontent.com/tracykteal/chicken-naming/master/chicken-naming.ipynb')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 200, body: '', headers: {
          'ETag' => 'e422b2e5bec8dddc1d2b99fd9908b6c8d074f5a270b41b589468a90bf13daabf',
          'Content-Type' => 'text/plain',
          'Cache-Control' => 'max-age=300',
          'Content-Length' => 5373,
          'Accept-Ranges' => 'bytes'
        })
    end

    def mock_github_bad_head_request!
      stub_request(:head, 'http://github.com/datadryad/dryad-app/raw/main/app/assets/images/favicon.ico')
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

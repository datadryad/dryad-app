module Mocks

  module Ror

    RSpec.configure do |config|
      config.before(:each) do
        def mock_ror!
          stub_request(:get, %r{api\.ror\.org/organizations\?query})
            .with(
              headers: {
                'Content-Type' => 'application/json'
              }
            ).to_return(status: 200, body: '', headers: {})
        end
      end
    end

  end

end

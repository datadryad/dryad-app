module Mocks

  module Ror

    # rubocop:disable Style/RegexpLiteral
    RSpec.configure do |config|
      config.before(:each) do
        def mock_ror!
          stub_request(:get, /api\.ror\.org\/organizations\?query/)
            .with(
              headers: {
                'Content-Type' => 'application/json'
              }
            ).to_return(status: 200, body: '', headers: {})
        end
      end
    end
    # rubocop:enable Style/RegexpLiteral

  end

end

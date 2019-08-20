module RorHelper

  def mock_query(query:, file:)
    stub_request(:get, "https://api.ror.org/organizations?query=#{query}")
      .with(
        headers: {
          'Content-Type' => 'application/json'
        }
      )
      .to_return(status: 200, body:  File.new(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', file)),
                 headers: {})
  end
end

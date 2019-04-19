module Mocks

  module Ror

    RSpec.configure do |config|
      config.before(:each) do
        def mock_ror!
          # Mock a ROR Organization query
          stub_request(:get, %r{api\.ror\.org/organizations\?query.*})
            .with(
              headers: {
                'Content-Type' => 'application/json'
              }
            ).to_return(status: 200, body: {
              'number_of_results': 1,
              'time_taken': 3,
              'items': [
                {
                  'id': "https://ror.org/TEST",
                  'name': "University of Testing",
                  'types': ['Education'],
                  'links': ["http://example.org/test"],
                  'aliases': ['testing'],
                  'acronyms': ['TST'],
                  'wikipedia_url': "http://example.org/wikipedia/wiki/test",
                  'labels': [{ 'iso639': 'id', 'label': "University of Testing" }],
                  'country': { 'code': 'US', 'name': 'United States of America' },
                  'external_ids': { 'GRID': { 'prefered': "grid.test.123" } }
                },
                {
                  'id': "https://ror.org/TEST2",
                  'name': "University of Testing v2",
                  'types': ['Education'],
                  'links': ["http://example.org/test2"],
                  'aliases': ['testing'],
                  'acronyms': ['TST2'],
                  'wikipedia_url': "http://example.org/wikipedia/wiki/test2",
                  'labels': [{ 'iso639': 'id', 'label': "University of Testing v2" }],
                  'country': { 'code': 'US', 'name': 'United States of America' },
                  'external_ids': { 'GRID': { 'prefered': "grid.test.123v2" } }
                }
              ]
              # 'items': ['country': { 'country_name': Faker::Space.planet }]
            }.to_json, headers: {})

            # Mock a request for a specific ROR Organization
            stub_request(:get, %r{api\.ror\.org/organizations/.+})
            .with(
              headers: {
                'Content-Type' => 'application/json'
              }
            ).to_return(status: 200, body: {
              'id': "https://ror.org/TEST",
              'name': "University of Testing",
              'types': ['Education'],
              'links': ["http://example.org/test"],
              'aliases': ['testing'],
              'acronyms': ['TST'],
              'wikipedia_url': "http://example.org/wikipedia/wiki/test",
              'labels': [{ 'iso639': 'id', 'label': "University of Testing" }],
              'country': { 'code': 'US', 'name': 'United States of America' },
              'external_ids': { 'GRID': { 'prefered': "grid.test.123" } }
            }.to_json, headers: {})
        end
      end
    end

  end

end

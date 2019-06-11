module Mocks

  module Ror

    def mock_ror!(user = nil)
      stub_ror_heartbeat_check
      stub_ror_name_lookup(name: user.present? && user.affiliation.present? ? user.affiliation.long_name : nil)
      stub_ror_id_lookup(university: user.present? && user.affiliation.present? ? user.affiliation.long_name : nil)
    end

    def stub_ror_heartbeat_check
      stub_request(:get, "https://api.ror.org/heartbeat")
        .with(
           headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby'
           })
        .to_return(status: 200, body: "", headers: {})
    end

    # rubocop:disable Metrics/MethodLength
    def stub_ror_id_lookup(university: Faker::Educator.university, country: 'United States of America')
      # Mock a request for a specific ROR Organization
      stub_request(:get, %r{api\.ror\.org/organizations/.+})
        .with(
          headers: {
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 200, body: {
          'id': 'https://ror.org/TEST',
          'name': university,
          'types': ['Education'],
          'links': ['http://example.org/test'],
          'aliases': ['testing'],
          'acronyms': ['TST'],
          'wikipedia_url': 'http://example.org/wikipedia/wiki/test',
          'labels': [{ 'iso639': 'id', 'label': university }],
          'country': { 'country_code': 'US', 'country_name': country },
          'external_ids': { 'GRID': { 'prefered': 'grid.test.123' } }
        }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    def stub_ror_name_lookup(name: Faker::Educator.university)
      # Mock a ROR Organization query
      stub_request(:get, %r{api\.ror\.org/organizations\?query(.\s)*})
        .with(
          headers: {
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 200, body: {
          'number_of_results': 2,
          'time_taken': 3,
          'items': [
            {
              'id': 'https://ror.org/TEST',
              'name': name,
              'types': ['Education'],
              'links': ['http://example.org/test'],
              'aliases': ['testing'],
              'acronyms': ['TST'],
              'wikipedia_url': 'http://example.org/wikipedia/wiki/test',
              'labels': [{ 'iso639': 'id', 'label': name }],
              'country': { 'country_code': 'US', 'country_name': 'United States of America' },
              'external_ids': { 'GRID': { 'prefered': 'grid.test.123' } }
            },
            {
              'id': 'https://ror.org/TEST2',
              'name': 'University of Testing v2',
              'types': ['Education'],
              'links': ['http://example.org/test2'],
              'aliases': ['testing'],
              'acronyms': ['TST2'],
              'wikipedia_url': 'http://example.org/wikipedia/wiki/test2',
              'labels': [{ 'iso639': 'id', 'label': 'University of Testing v2' }],
              'country': { 'country_code': 'US', 'country_name': 'United States of America' },
              'external_ids': { 'GRID': { 'prefered': 'grid.test.123v2' } }
            }
          ]
        }.to_json, headers: { 'Content-Type' => 'application/json' })
    end
    # rubocop:enable Metrics/MethodLength

  end

end

module Mocks

  module CrossrefFunder

    def mock_funders!(_user = nil)
      stub_funder_name_lookup
    end

    def stub_funder_name_lookup(name: Faker::Company.name)
      stub_request(:get, %r{api\.crossref\.org/funders\?query(.\s)*})
        .with(
          headers: {
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 200, body:
                                   {
                                     status: 'ok',
                                     'message-type': 'funder-list',
                                     'message-version': '1.0.0',
                                     message: { 'items-per-page': 20,
                                                query: { 'start-index': 0, 'search-terms': 'Solution' },
                                                'total-results': 2,
                                                items: [{ id: '501100003025',
                                                          location: 'Canada',
                                                          name: name,
                                                          'alt-names': ["Alternate of #{name}"],
                                                          uri: 'http://dx.doi.org/10.13039/501100003025',
                                                          replaces: [],
                                                          'replaced-by': [],
                                                          tokens: %w[effigis effigis geo solutions] },
                                                        { id: '100009023',
                                                          location: nil,
                                                          name: 'WSN Environmental Solutions',
                                                          'alt-names': [],
                                                          uri: 'http://dx.doi.org/10.13039/100009023',
                                                          replaces: [],
                                                          'replaced-by': [],
                                                          tokens: %w[wsn environmental solutions] },
                                                        { id: '501100000145',
                                                          location: nil,
                                                          name: 'Alberta Innovates - Health Solutions',
                                                          'alt-names': ['AIHS'],
                                                          uri: 'http://dx.doi.org/10.13039/501100000145',
                                                          replaces: [],
                                                          'replaced-by': [],
                                                          tokens: %w[alberta innovates health solutions aihs] }] }
                                   }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

  end

end

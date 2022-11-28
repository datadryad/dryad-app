module Mocks

  module Counter
    def mock_counter!
      json =
        {
          data: [
            { id: '9459a75c-a45f-49f0-8e96-94cce0d7c5fd',
              type: 'events',
              attributes: {
                'subj-id': 'https://api.datacite.org/reports/bd4082c3-f1ac-4202-9cd9-fa951b8fda42',
                'obj-id': 'https://doi.org/10.5061/dryad.234',
                'source-id': 'datacite-usage',
                'relation-type-id': 'unique-dataset-requests-regular',
                total: 67,
                'message-action': 'create',
                'source-token': '43ba99ae-5cf0-11e8-9c2d-fa7ae01bbebc',
                license: 'https://creativecommons.org/publicdomain/zero/1.0/',
                'occurred-at': '2011-02-01T00:00:00.000Z',
                timestamp: '2019-09-07T23:53:57.716Z'
              } }
          ],
          links: {
            self: 'https://api.datacite.org/events?doi=10.5061%2Fdryad.234&page%5Bnumber%5D=1&page%5Bsize%5D=10&source-id=datacite-usage&relation-type-id=unique-dataset-investigations-regular,unique-dataset-investigations-machine,unique-dataset-requests-regular,unique-dataset-requests-machine',
            next: 'https://api.datacite.org/events?doi=10.5061%2Fdryad.234&page%5Bnumber%5D=2&page%5Bsize%5D=10&relation-type-id=unique-dataset-investigations-regular%2Cunique-dataset-investigations-machine%2Cunique-dataset-requests-regular%2Cunique-dataset-requests-machine&source-id=datacite-usage'
          }
        }.to_json

      stub_request(:get, %r{api\.datacite\.org/events})
        .with(
          headers: {
            'Connection' => 'close',
            'Host' => 'api.datacite.org'
          }
        )
        .to_return(status: 200, body: json, headers: { 'Content-Type' => 'application/json' })
    end
  end
end

module Mocks

  module Datacite

    def mock_datacite!
      allow_any_instance_of(Stash::Doi::DataciteGen).to receive(:update_metadata).and_return(true)

      stub_request(:post, /mds.test.datacite.org\/metadata/)
        .with(
           body: /.*/,
           headers: {
            'Accept'=>'text/html,application/json,application/xml;q=0.9, text/plain;q=0.8,image/png,*/*;q=0.5',
            'Authorization'=>/Basic.*/,
            'Content-Type'=>'application/xml;charset=UTF-8',
            'Host'=>'mds.test.datacite.org',
            'User-Agent'=>/.*/
          })
        .to_return(status: 201, body: "", headers: {})


      stub_request(:put, /mds.test.datacite.org\/doi\//)
        .with(
          body: /.*/,
          headers: {
            'Accept'=>'text/html,application/json,application/xml;q=0.9, text/plain;q=0.8,image/png,*/*;q=0.5',
            'Authorization'=>/Basic.*/,
            'Content-Type'=>'text/plain;charset=UTF-8',
            'Host'=>'mds.test.datacite.org',
            'User-Agent'=>/.*/
          })
        .to_return(status: 201, body: "", headers: {})
    end

  end

end

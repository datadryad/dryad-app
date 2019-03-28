require 'rsolr'

module Mocks

  module RSolr

    def mock_solr!
      # Mock the Solr connection
      allow(::RSolr).to receive(:connect).and_return(nil)

      # The StashDiscovery::LatestController.index attempts to contact Solr and the Rails.cache for
      # the list of 'Recent Datasets' on the home page. We have to set one of the controller's instance
      # variables to an empty array so the view doesn't blow up
      allow_any_instance_of(LatestController).to receive(:set_cached_latest) do |dbl|
        dbl.instance_variable_set(:@document_list, [])
      end

      # Stub any requests to Solr
      stub_request(:any, 'http://127.0.0.1:8983/solr/').to_return(status: 200, body: '', headers: {})
    end

  end

end

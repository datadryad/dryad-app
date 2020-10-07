require 'rsolr'

module Mocks

  module RSolr

    def mock_solr!(include_identifier: nil)
      @include_identifier = include_identifier

      # Mock the Solr connection
      solr = double('RSolr')
      allow(solr).to receive(:paginate).and_return(paginated_results)
      allow(::RSolr).to receive(:connect).and_return(solr)

      # The StashDiscovery::LatestController.index attempts to contact Solr and the Rails.cache for
      # the list of 'Recent Datasets' on the home page. We have to set one of the controller's instance
      # variables to an empty array so the view doesn't blow up
      allow_any_instance_of(LatestController).to receive(:set_cached_latest) do |dbl|
        dbl.instance_variable_set(:@document_list, [])
      end
    end

    def paginated_results
      { 'response' =>
       { 'numFound' => 109,
         'start' => 10,
         'docs' =>
        [{ 'dc_identifier_s' => "doi:#{@include_identifier&.identifier || '10.5061/dryad.abc123'}" },
         { 'dc_identifier_s' => 'doi:10.5061/dryad.1r7m0' },
         { 'dc_identifier_s' => 'doi:10.5061/dryad.2b65b' },
         { 'dc_identifier_s' => 'doi:10.5061/dryad.h7s57' },
         { 'dc_identifier_s' => 'doi:10.5061/dryad.5j2v6' }] } }
    end

  end

end

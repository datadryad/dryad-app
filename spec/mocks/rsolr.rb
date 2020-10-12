require 'rsolr'

module Mocks

  module RSolr

    def mock_solr!(include_identifier: nil)
      @include_identifier = include_identifier

      # Mock the Solr connection
      # http://someserver.org:8983/solr/geoblacklight/select?fl=dc_identifier_s&q=data&rows=10&start=0&wt=json
      stub_request(:get, %r{solr/geoblacklight}).to_return(status: 200, body: default_results, headers: {})
      stub_request(:post, %r{solr/geoblacklight}).to_return(status: 200, body: [], headers: {})
      stub_request(:get, %r{solr/geoblacklight.*fq=dryad_author_affiliation}).to_return(status: 200, body: trivial_results, headers: {})
      stub_request(:get, %r{solr/geoblacklight.*fq=timestamp}).to_return(status: 200, body: trivial_results, headers: {})

      # The StashDiscovery::LatestController.index attempts to contact Solr and the Rails.cache for
      # the list of 'Recent Datasets' on the home page. We have to set one of the controller's instance
      # variables to an empty array so the view doesn't blow up
      allow_any_instance_of(LatestController).to receive(:set_cached_latest) do |dbl|
        dbl.instance_variable_set(:@document_list, [])
      end
    end

    def default_results
      { 'response' =>
       { 'numFound' => 110,
         'start' => 10,
         'docs' =>
        [{ 'dc_identifier_s' => "doi:#{@include_identifier&.identifier || '10.5061/dryad.abc123'}" },
         { 'dc_identifier_s' => 'doi:10.5061/dryad.1r7m0' },
         { 'dc_identifier_s' => 'doi:10.5061/dryad.2b65b' },
         { 'dc_identifier_s' => 'doi:10.5061/dryad.h7s57' },
         { 'dc_identifier_s' => 'doi:10.5061/dryad.5j2v6' }] } }.to_json
    end

    def trivial_results
      { 'response' =>
       { 'numFound' => 1,
         'start' => 1,
         'docs' =>
         [{ 'dc_identifier_s' => "doi:#{@include_identifier&.identifier || '10.5061/dryad.abc123'}" }] } }.to_json
    end

  end

end

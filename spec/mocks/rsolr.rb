require 'rsolr'

module Mocks

  module RSolr

    def mock_solr!(include_identifier: nil)
      @include_identifier = include_identifier

      # Mock the Solr connection
      # http://someserver.org:8983/solr/dryad/select?fl=dc_identifier_s&q=data&rows=10&start=0&wt=json
      stub_request(:get, %r{solr/dryad}).to_return(status: 200, body: default_results, headers: {})
      stub_request(:post, %r{solr/dryad}).to_return(status: 200, body: [], headers: {})
      stub_request(:get, %r{solr/dryad.*fq=dryad_author_affiliation}).to_return(status: 200, body: trivial_results, headers: {})
      stub_request(:get, %r{solr/dryad.*fq=updated_at_dt}).to_return(status: 200, body: trivial_results, headers: {})
      stub_request(:get, %r{solr/dryad.*fq=rw_sim}).to_return(status: 200, body: trivial_results, headers: {})

      # The StashDiscovery::LatestController.index attempts to contact Solr and the Rails.cache for
      # the list of 'Recent Datasets' on the home page. We have to set one of the controller's instance
      # variables to an empty array so the view doesn't blow up
      allow_any_instance_of(LatestController).to receive(:set_cached_latest) do |dbl|
        dbl.instance_variable_set(:@document_list, [])
      end
    end

    def mock_solr_frontend!
      stub_request(:get, %r{solr/dryad}).to_return(status: 200, body: detailed_results, headers: {})
    end

    def mock_rors_solr!(include_rors: [])
      @include_rors = include_rors

      # Mock the ROR Solr connection
      # http://someserver.org:8983/solr/dryad/select?fl=dc_identifier_s&q=data&rows=10&start=0&wt=json
      stub_request(:get, %r{solr/rors*}).to_return(status: 200, body: ror_results, headers: {})
    end

    def default_results
      {
        'response' => {
          'numFound' => 110,
          'start' => 10,
          'docs' => [
            { 'dc_identifier_s' => "doi:#{@include_identifier&.identifier || '10.5061/dryad.abc123'}" },
            { 'dc_identifier_s' => 'doi:10.5061/dryad.1r7m0' },
            { 'dc_identifier_s' => 'doi:10.5061/dryad.2b65b' },
            { 'dc_identifier_s' => 'doi:10.5061/dryad.h7s57' },
            { 'dc_identifier_s' => 'doi:10.5061/dryad.5j2v6' }
          ]
        }
      }.to_json
    end

    def trivial_results
      { 'response' =>
        { 'numFound' => 1,
          'start' => 1,
          'docs' =>
            [{ 'dc_identifier_s' => "doi:#{@include_identifier&.identifier || '10.5061/dryad.abc123'}" }] } }.to_json
    end

    def detailed_results
      results = Array.new(20) do
        {
          'dc_identifier_s' => 'doi:10.5061/dryad.1r7m0',
          'dc_title_s' => Faker::Lorem.sentence(word_count: 10),
          'dc_creator_sm' => Array.new(rand(1..5)) { "#{Faker::Name.last_name}, #{Faker::Name.first_name}" },
          'dc_description_s' => Faker::Lorem.paragraph,
          'dc_subject_sm' => Array.new(rand(4..8)) { Faker::Lorem.word },
          'dct_issued_dt' => Faker::Time.between_dates(from: Date.today - 2.years, to: Date.today)
        }
      end
      {
        'response' => {
          'numFound' => 20,
          'start' => 0,
          'docs' => results
        },
        'facet_counts' => {
          'facet_fields' => {
            'ror_ids_sm' =>
            ["https://ror.org/#{Faker::Number.number(digits: 7)}", 6,
             "https://ror.org/#{Faker::Number.number(digits: 7)}", 5],
            'dryad_author_affiliation_id_sm' =>
            ["https://ror.org/#{Faker::Number.number(digits: 7)}", 6,
             "https://ror.org/#{Faker::Number.number(digits: 7)}", 5],
            'dryad_related_publication_issn_s' =>
            ["#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}", 4,
             "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}", 3],
            'solr_year_i' =>
            [Date.today.year, 6, (Date.today - 1.year).year, 5],
            'dryad_dataset_file_ext_sm' => ['md', 10, 'csv', 6, 'tsv', 5],
            'dc_subject_sm' =>
            [Faker::Lorem.word, 5, Faker::Lorem.word, 5, Faker::Lorem.word, 3]
          }
        }
      }.to_json
    end

    def ror_results
      {
        'response' => {
          'numFound' => 1,
          'start' => 1,
          'docs' => @include_rors.map(&:index_mappings)
        }
      }.to_json
    end

  end

end

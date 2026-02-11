require 'rails_helper'
require 'json'

module Integrations
  # Example of a Crossref API journal response: view-source:http://api.crossref.org/journals?query=Journal%20of%20The%20Royal%20Society%20Interface
  CROSSREF_JOURNAL_RESPONSE = {
    'status' => 'ok',
    'message-type' => 'journal-list',
    'message-version' => '1.0.0',
    'message' => {
      'items-per-page' => 20,
      'query' => {
        'start-index' => 0,
        'search-terms' => 'Journal of The Royal Society Interface'
      },
      'total-results' => 1,
      'items' => [
        {
          'last-status-check-time' => 1_553_443_941_216,
          'counts' => {
            'total-dois' => 3163,
            'current-dois' => 630,
            'backfile-dois' => 2533
          },
          'breakdowns' => {
            'dois-by-issued-year' => [[2014, 378]]
          },
          'publisher' => 'The Royal Society',
          'coverage' => {
            'affiliations-current' => 0.15714286267757416
          },
          'title' => 'Journal of The Royal Society Interface',
          'subjects' => [{ 'name' => 'Biochemistry', 'ASJC' => 1303 }],
          'coverage-type' => {
            'all' => { 'last-status-check-time' => 1_553_443_938_923 },
            'backfile' => { 'last-status-check-time' => 1_553_443_938_136 },
            'current' => { 'last-status-check-time' => 1_553_443_937_362 }
          },
          'flags' => { 'deposits-abstracts-current' => false },
          'ISSN' => %w[1742-5662 1742-5689],
          'issn-type' => [
            { 'value' => '1742-5662', 'type' => 'electronic ' },
            { 'value' => '1742-5689', 'type' => 'print' }
          ]
        }
      ]
    }
  }.freeze

  # Example of a Crossref API response for a work: view-source:http://api.crossref.org/works/10.1101/139345
  CROSSREF_WORK_RESPONSE = {
    'status' => 'ok',
    'message-type' => 'journal-list',
    'message-version' => '1.0.0',
    'message' => {
      'total-results' => 1,
      'institution' => {
        'name' => 'bioRxiv',
        'place' => ['-'],
        'acronym' => ['-']
      },
      'indexed' => { 'date-parts' => [[2019, 2, 18]], 'date-time' => '2019-02-18T00:54:11Z', 'timestamp' => 1_550_451_251_128 },
      'posted' => { 'date-parts' => [[2017, 5, 17]] },
      'group-title' => 'Physiology',
      'reference-count' => 0,
      'publisher' => 'Cold Spring Harbor Laboratory',
      'content-domain' => { 'domain' => [], 'crossmark-restriction' => false },
      'short-container-title' => [],
      'accepted' => { 'date-parts' => [[2017, 5, 17]] },
      'abstract' => 'The aim of the present study was to examine if genetic factors associated with pain perception ...',
      'DOI' => '10.1101\/139345',
      'type' => 'posted-content',
      'created' => { 'date-parts' => [[2017, 5, 18]], 'date-time' => '2017-05-18T05:10:13Z', 'timestamp' => 1_495_084_213_000 },
      'source' => 'Crossref',
      'is-referenced-by-count' => 0,
      'title' => ['The Mu-Opioid Receptor Gene OPRM1 As A Genetic Marker For Placebo Analgesia'],
      'prefix' => '10.1101',
      'author' => [
        { 'ORCID' => 'http:\/\/orcid.org\/0000-0002-9299-7260', 'authenticated-orcid' => false, 'given' => 'Per M.', 'family' => 'Aslaksen',
          'sequence' => 'first', 'affiliation' => [] },
        { 'given' => 'June Thorvaldsen', 'family' => 'Forsberg', 'sequence' => 'additional', 'affiliation' => [] }
      ],
      'member' => '246',
      'container-title' => [],
      'original-title' => [],
      'link' => [{
        'URL' => 'https:\/\/syndication.highwire.org\/content\/doi\/10.1101\/139345',
        'content-type' => 'unspecified',
        'content-version' => 'vor',
        'intended-application' => 'similarity-checking'
      }],
      'deposited' => { 'date-parts' => [[2017, 5, 18]], 'date-time' => '2017-05-18T05:10:33Z', 'timestamp' => 1_495_084_233_000 },
      'score' => 1.0,
      'subtitle' => [],
      'short-title' => [],
      'issued' => { 'date-parts' => [[2017, 5, 17]] },
      'references-count' => 0,
      'URL' => 'http:\/\/dx.doi.org\/10.1101\/139345',
      'relation' => {
        'is-preprint-of' => [
          {
            'id' => '10.1111/test',
            'id-type' => 'doi'
          }
        ]
      },
      'subtype' => 'preprint'
    }
  }.freeze
  describe Crossref do

    before(:each) do
      # I don't see any factories here, so just creating a resource manually
      @user = StashEngine::User.create(
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@datadryad.org',
        tenant_id: 'ucop'
      )
      @identifier = StashEngine::Identifier.create(identifier: '10.1234/abcd123')
      @resource = StashEngine::Resource.create(current_editor_id: @user.id, tenant_id: 'ucop', identifier_id: @identifier.id)

      allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)
      allow(Serrano).to receive(:works).and_return([CROSSREF_WORK_RESPONSE])
      allow(Serrano).to receive(:journals).and_return(CROSSREF_JOURNAL_RESPONSE)
    end

    describe '#query_by_doi' do
      it 'returns nil if the DOI is nil' do
        expect(Crossref.send(:query_by_doi, doi: nil)).to eql(nil)
      end

      it 'returns a parsed json response' do
        expect(Crossref.send(:query_by_doi, doi: '10.123/12345').is_a?(Hash)).to eql(true)
      end
    end

    describe '#query_by_preprint_doi' do
      it 'returns nil if the DOI is nil' do
        expect(Crossref.send(:query_by_preprint_doi, doi: nil)).to eql(nil)
      end

      it 'returns a parsed json response' do
        expect(Crossref.send(:query_by_preprint_doi, doi: '10.123/12345').is_a?(Hash)).to eql(true)
      end
    end

    describe '#query_by_author_title' do
      it 'returns nil if the resource is nil' do
        expect(Crossref.send(:query_by_author_title, resource: nil)).to eql(nil)
      end

      it 'returns nil if the resource has no title' do
        expect(Crossref.send(:query_by_author_title, resource: @resource)).to eql(nil)
      end

      it 'returns nil if Crossref did not find a suitable match' do
        @resource.title = 'Testing again' # Mocked title is above
        expect(Crossref.send(:query_by_author_title, resource: @resource)).to eql(nil)
      end

      it 'returns a parsed json response' do
        allow(Crossref).to receive(:valid_serrano_works_response).and_return(true)
        @resource.title = 'Mu-Opioid Receptor Gene OPRM1 As A Genetic Marker'
        allow(Crossref).to receive(:match_resource_with_crossref_record).and_return([0.5, { 'title' => @resource.title }])
        expect(Crossref.send(:query_by_author_title, resource: @resource).is_a?(Hash)).to eql(true)
      end
    end

    describe 'Crossref query helper methods' do

      before(:each) do
        identifier = create(:identifier, identifier: 'ABCD')
        @resource = create(:resource, title: ' Testing  Again\\', identifier: identifier)
        create(:resource_publication, publication_issn: '1234-5678', resource_id: @resource.id)
        @resource.authors = [
          StashEngine::Author.new(author_first_name: 'John', author_last_name: 'Doe', author_orcid: '12345'),
          StashEngine::Author.new(author_first_name: 'Jane', author_last_name: 'Van-jones')
        ]
        @resource.save

        @names = @resource.authors.map do |author|
          { first: author.author_first_name&.downcase, last: author.author_last_name&.downcase }
        end
        @orcids = @resource.authors.map { |author| author.author_orcid&.downcase }
      end

      describe '#match_resource_with_crossref_record' do
        before(:each) do
          @resp = {
            'items' => [
              { 'title' => ['Testing Again'], 'score' => 34.78456 },
              { 'title' => ['Weird Title'], 'score' => 2.231 }
            ]
          }
        end

        it 'returns nil if the resource is nil' do
          expect(Crossref.send(:match_resource_with_crossref_record, resource: nil, response: @resp)).to eql(nil)
        end

        it 'returns nil if the response from Crossref was nil' do
          expect(Crossref.send(:match_resource_with_crossref_record, resource: @resource, response: {})).to eql(nil)
        end

        it 'returns a the match with the highest score' do
          @resource.title = 'weird title of a dataset'
          match = Crossref.send(:match_resource_with_crossref_record, resource: @resource, response: @resp)
          expect(match.last['title']).to eql(@resp['items'].last['title'])
        end
      end

      describe '#crossref_item_scoring' do
        it 'returns zero id the resource is nil' do
          expect(Crossref.send(:crossref_item_scoring, nil, { 'title' => 'ABC' }, nil, nil)).to eql(0.0)
        end

        it 'returns zero id the resource has no title' do
          @resource.title = nil
          expect(Crossref.send(:crossref_item_scoring, @resource, {}, nil, nil)).to eql(0.0)
        end

        it 'returns zero id the Crossref response does not have a title' do
          expect(Crossref.send(:crossref_item_scoring, @resource, {}, nil, nil)).to eql(0.0)
        end

        it 'returns a high score when the titles are close' do
          item = { 'title' => ['Testing Item Scoring'] }
          @resource.title = 'Data from: Testing Scoring'
          expect(Crossref.send(:crossref_item_scoring, @resource, item, nil, nil).first >= 0.5).to eql(true)
        end

        it 'returns a low score when the titles are dissimilar' do
          item = { 'title' => ['Testing Item Scoring'] }
          @resource.title = 'A completely different scoring title'
          expect(Crossref.send(:crossref_item_scoring, @resource, item, nil, nil).first < 0.5).to eql(true)
        end

        it 'sets the item[`score`] and item[`provenance_score`]' do
          item = { 'title' => ['Testing Item Scoring'], 'score' => 12.3 }
          @resource.title = 'A completely different scoring title'
          item = Crossref.send(:crossref_item_scoring, @resource, item, nil, nil).last
          expect(item['score'].present?).to eql(true)
          expect(item['provenance_score'].present?).to eql(true)
          expect(item['provenance_score']).to eql(12.3)
        end
      end

      describe '#crossref_author_scoring' do
        it 'returns zero if the resource has no authors' do
          auth = { 'ORCID' => 'ABCD' }
          expect(Crossref.send(:crossref_author_scoring, [], [], auth)).to eql(0.0)
        end

        it 'returns zero if there are no author matches' do
          auth = { 'ORCID' => 'ABCD', 'given' => 'Tester', 'family' => 'Mc-testing' }
          expect(Crossref.send(:crossref_author_scoring, @names, @orcids, auth)).to eql(0.0)
        end

        it 'returns .1 if we have one ORCID match' do
          auth = { 'ORCID' => '12345' }
          expect(Crossref.send(:crossref_author_scoring, @names, @orcids, auth)).to eql(0.1)
        end

        it 'returns .025 if all we can match is the last name' do
          auth = { 'ORCID' => 'ABCD', 'given' => 'Tester', 'family' => 'Doe' }
          expect(Crossref.send(:crossref_author_scoring, @names, @orcids, auth)).to eql(0.025)
        end

        it 'returns .05 if all we can match is the author first+last names' do
          auth = { 'ORCID' => 'ABCD', 'given' => 'John', 'family' => 'Doe' }
          expect(Crossref.send(:crossref_author_scoring, @names, @orcids, auth)).to eql(0.05)
        end

        it 'returns .15 if we can match the first+last names and the ORCID' do
          auth = { 'ORCID' => '12345', 'given' => 'John', 'family' => 'Doe' }
          expect(Crossref.send(:crossref_author_scoring, @names, @orcids, auth)).to eql(0.15)
        end
      end

      describe '#valid_serrano_works_response' do
        it 'returns false if the Crossref/Serrano response is nil' do
          resp = nil
          expect(Crossref.send(:valid_serrano_works_response, resp)).to eql(false)
        end
        it 'returns false if the Crossref/Serrano response is does not have a `message`' do
          resp = { 'testing' => '' }
          expect(Crossref.send(:valid_serrano_works_response, resp)).to eql(false)
        end
        it 'returns false if the Crossref/Serrano response does not have a `total-results' do
          resp = { 'message' => { 'items' => [{ 'a' => 'b' }] } }
          expect(Crossref.send(:valid_serrano_works_response, resp)).to eql(false)
        end
        it 'returns false if the Crossref/Serrano response has zero results' do
          resp = { 'message' => { 'total-results' => 0, 'items' => [{ 'a' => 'b' }] } }
          expect(Crossref.send(:valid_serrano_works_response, resp)).to eql(false)
        end
        it 'returns false if the Crossref/Serrano response does not have `items`' do
          resp = { 'message' => { 'total-results' => 1 } }
          expect(Crossref.send(:valid_serrano_works_response, resp)).to eql(false)
        end
        it 'returns false if the Crossref/Serrano response has a [`message`][`items`] that is empty' do
          resp = { 'message' => { 'total-results' => 1, 'items' => [] } }
          expect(Crossref.send(:valid_serrano_works_response, resp)).to eql(false)
        end

        it 'returns true if the Crossref/Serrano response has a [`message`][`items`].first' do
          resp = { 'message' => { 'total-results' => 1, 'items' => [{ 'a' => 'b' }] } }
          expect(Crossref.send(:valid_serrano_works_response, resp)).to eql(true)
        end
      end

      describe '#title_author_query_params' do
        it 'returns nil if the resource is nil' do
          expect(Crossref.send(:title_author_query_params, nil)).to eql([nil, nil, nil])
        end

        it 'returns an array containing the [ISSN, TITLE, AUTHOR LAST NAMES]' do
          issn, title_query, author_query = Crossref.send(:title_author_query_params, @resource)
          expect(issn).to eql('1234-5678')
          expect(title_query).to eql('Testing+Again%5C')
          expect(author_query).to eql('Doe+Van-jones')
        end
      end

      describe '#get_journal_issn' do
        it 'returns nil if the hash is empty' do
          expect(Crossref.send(:get_journal_issn, nil)).to eql(nil)
          expect(Crossref.send(:get_journal_issn, {})).to eql(nil)
          expect(Crossref.send(:get_journal_issn, 'container-title' => '')).to eql(nil)
        end

        it 'returns nil if the response from Crossref is empty' do
          allow(Serrano).to receive(:journals).and_return(nil)
          expect(Crossref.send(:get_journal_issn, 'container-title' => 'ABCD')).to eql(nil)
        end

        it 'returns the ISSN' do
          expect(Crossref.send(:get_journal_issn,
                               'container-title' => 'ABCD')).to eql(CROSSREF_JOURNAL_RESPONSE['message']['items'].first['ISSN'])
        end
      end
    end
  end
end

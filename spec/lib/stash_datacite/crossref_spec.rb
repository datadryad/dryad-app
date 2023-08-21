require 'rails_helper'

module Stash
  module Import

    TITLE = 'High-skilled labour mobility in Europe before and after the 2004 enlargement'.freeze
    AUTHOR = [
      { 'ORCID' => 'http://orcid.org/0000-0002-0955-3483', 'given' => 'Julia M.', 'family' => 'Petersen',
        'affiliation' => [{ 'name' => 'Hotel California' }] },
      { 'ORCID' => 'http://orcid.org/0000-0002-1212-2233', 'given' => 'Michelangelo', 'family' => 'Snow',
        'affiliation' => [{ 'name' => 'Catalonia' }] }
    ].freeze
    ABSTRACT = 'Flip-flop gates must work. In fact, few biologists would disagree with the emulation of expert systems. ' \
               'Our focus in this work is not on whether the partition table and the UNIVAC computer can collude to accomplish this ' \
               'purpose, but rather on presenting an analysis of e-commerce (Newt).'.freeze

    FUNDER = [{ 'name' => 'National Heart, Lung, and Blood Institute',
                'award' => %w[R01-HL30077 R01-HL90880 R01-HL123526 R01-HL085727 R01-HL085844 P01-HL080101] },
              { 'name' => 'U.S. Department of Veterans Affairs', 'award' => ['I01 BX000576', 'I01 CX001490'] },
              { 'name' => 'Országos Tudományos Kutatási Alapprogramok', 'award' => ['OTKA101196'] },
              { 'name' => 'California Institute for Regenerative Medicine', 'award' => ['TR3 05626'] },
              { 'name' => 'American Heart Association', 'award' => ['14GRNT20510041'] }].freeze

    URL = 'http://dx.doi.org/10.1073/pnas.1718211115'.freeze

    DOI = '10.1073/pnas.1718211115'.freeze
    PAST_PUBLICATION_DATE = [2018, 0o1, 0o1].freeze
    FUTURE_PUBLICATION_DATE = [2035, 0o1, 0o1].freeze
    PUBLISHER = 'Ficticious Journal'.freeze

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
        'relation' => {},
        'subtype' => 'preprint'
      }
    }.freeze
    describe Crossref do

      before(:each) do
        # I don't see any factories here, so just creating a resource manually
        @user = StashEngine::User.create(
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          tenant_id: 'ucop'
        )
        @identifier = StashEngine::Identifier.create(identifier: '10.1234/abcd123')
        @resource = StashEngine::Resource.create(user_id: @user.id, tenant_id: 'ucop', identifier_id: @identifier.id)

        allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)
        allow(Serrano).to receive(:works).and_return([CROSSREF_WORK_RESPONSE])
        allow(Serrano).to receive(:journals).and_return(CROSSREF_JOURNAL_RESPONSE)
      end

      describe '#populate_title' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'title' => [TITLE] })
        end

        it 'extracts the title' do
          @cr.send(:populate_title)
          expect(@resource.title).to eql(TITLE)
        end

        it "doesn't puke or overwrite with no title" do
          @title = 'meow meow'
          @resource.update(title: @title)
          @cr = Crossref.new(resource: @resource, crossref_json: {})
          @cr.send(:populate_title)
          expect(@resource.title).to eql(@title)
        end

        it "doesn't puke or overwrite with blank title" do
          @title = 'meow meow'
          @resource.update(title: @title)
          @cr = Crossref.new(resource: @resource, crossref_json: { 'title' => [] })
          resp = @cr.send(:populate_title)
          expect(resp).to eql(nil)
          expect(@resource.title).to eql(@title)
        end
      end

      describe '#populate_authors' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'author' => AUTHOR })
        end

        it 'populates names' do
          @cr.send(:populate_authors)
          expect(@resource.authors.first.author_first_name).to eql(AUTHOR.first['given'])
          expect(@resource.authors.first.author_last_name).to eql(AUTHOR.first['family'])
          expect(@resource.authors[1].author_first_name).to eql(AUTHOR[1]['given'])
          expect(@resource.authors[1].author_last_name).to eql(AUTHOR[1]['family'])
        end

        it 'populates ORCIDs' do
          @cr.send(:populate_authors)
          expect(@resource.authors.first.author_orcid).to eql('0000-0002-0955-3483')
          expect(@resource.authors[1].author_orcid).to eql('0000-0002-1212-2233')
        end

        it 'populates affiliations' do
          @cr.send(:populate_authors)
          expect(@resource.authors.first.affiliation.long_name).to eql('Hotel California*')
        end

        it 'handles minimal data because lots of stuff is missing metadata' do
          @author_example = [{ 'family' => 'Petersen' }, { 'family' => 'Snow' }]
          @cr = Crossref.new(resource: @resource, crossref_json: { 'author' => @author_example })
          @cr.send(:populate_authors)
          expect(@resource.authors.length).to eql(2)
          expect(@resource.authors.first.author_orcid).to be_nil
          expect(@resource.authors[1].author_orcid).to be_nil
          expect(@resource.authors.first.affiliations.length).to eql(0)
          expect(@resource.authors[1].affiliations.length).to eql(0)
        end
      end

      describe '#populate_abstract' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'abstract' => ABSTRACT })
        end

        it 'fills in the abstract when it is supplied' do
          @cr.send(:populate_abstract)
          expect(@resource.descriptions.select { |d| d.description_type = 'abstract' }.first.description).to eql(ABSTRACT)
        end

        it "leaves off the abstract when it doesn't exist" do
          @cr = Crossref.new(resource: @resource, crossref_json: {})
          resp = @cr.send(:populate_abstract)
          expect(resp).to eql(nil)
          expect(@resource.descriptions.select { |d| d.description_type = 'abstract' }.length).to eql(0)
        end
      end

      describe '#populate_funders' do
        before(:each) do
          @funder_example = FUNDER.dup
          @cr = Crossref.new(resource: @resource, crossref_json: { 'funder' => @funder_example })
        end

        it 'populates a contributor and award for each award number' do
          @cr.send(:populate_funders)
          expect(@resource.contributors.length).to eql(11) # one entry for each award
        end

        it 'populates only one award for a contributor without any award number' do
          @funder_example[0] = { 'name' => 'National Heart, Lung, and Blood Institute' }
          @cr = Crossref.new(resource: @resource, crossref_json: { 'funder' => @funder_example })
          @cr.send(:populate_funders)
          expect(@resource.contributors.length).to eql(6)
        end

        it 'removes blank contributor entries before populating' do
          funders = [{ 'name' => '' }]
          funders << FUNDER
          cr = Crossref.new(resource: @resource, crossref_json: { 'funder' => funders.flatten })
          cr.send(:populate_funders)
          expect(@resource.contributors.length).to eql(11) # not 12, which it would be if the empty one hadn't been removed
        end

        it 'fills in funder name and award number for an individual entry' do
          @cr.send(:populate_funders)
          contrib = @resource.contributors.first
          expect(contrib.contributor_name).to eql('National Heart, Lung, and Blood Institute')
          expect(contrib.award_number).to eql('R01-HL30077')
          expect(contrib.contributor_type).to eql('funder')
        end

        it 'handles missing funders' do
          @cr = Crossref.new(resource: @resource, crossref_json: {})
          @cr.send(:populate_funders)
          expect(@resource.contributors.length).to eql(0)
        end
      end

      describe '#populate_article_type' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'URL' => URL })
        end

        it 'takes the DOI URL for the article and turns it into cites for this dataset' do
          @cr.send(:populate_article_type, {article_type: 'primary_article'})
          expect(@resource.related_identifiers.any?).to eql(true)
          expect(@resource.related_identifiers.first.related_identifier).to \
            eql(StashDatacite::RelatedIdentifier.standardize_doi(URL))
        end

        it 'ignores blank URLs' do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'URL' => '' })
          resp = @cr.send(:populate_article_type, {article_type: 'primary_article'})
          expect(resp).to eql(nil)
          expect(@resource.related_identifiers.length).to eql(0)
        end
      end

      describe '#populate_publication_date' do
        before(:each) do
          allow_any_instance_of(StashEngine::Resource).to receive(:submit_to_solr).and_return(true)
          @cr = Crossref.new(resource: @resource, crossref_json: { 'published-online' => { 'date-parts' => FUTURE_PUBLICATION_DATE } })
        end

        it 'sets the publication_date' do
          cr = Crossref.new(resource: @resource, crossref_json: { 'published-online' => { 'date-parts' => PAST_PUBLICATION_DATE } })
          cr.send(:populate_publication_date)
          expect(@resource.publication_date.strftime('%Y-%m-%d')).to eql(cr.send(:date_parts_to_date, PAST_PUBLICATION_DATE).strftime('%Y-%m-%d'))
        end

        it 'ignores blank published-online dates' do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'published-online' => nil })
          resp = @cr.send(:populate_publication_date)
          expect(resp).to eql(nil)
          expect(@resource.publication_date).to eql(nil)
        end
      end

      describe '#populate_publication_name' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'publisher' => PUBLISHER })
        end

        it 'sets the publication_name' do
          @cr.send(:populate_publication_name)
          expect(@resource.identifier.internal_data.select { |id| id.data_type == 'publicationName' }.first.value).to eql(PUBLISHER)
        end

        it 'ignores blank publisher names' do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'publisher' => nil })
          resp = @cr.send(:populate_publication_name)
          expect(resp).to eql(nil)
          expect(@resource.identifier.internal_data.none? { |id| id.data_type == 'publicationName' }).to eql(true)
        end
      end

      describe 'Date conversions' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: {})
          @date_as_array = [2019, 0o6, 24]
          @date_as_string = '2019-06-24'
        end

        it 'converts [yyyy, mm, dd] array to a Ruby Date' do
          date = @cr.send(:date_parts_to_date, @date_as_array)
          expect(date.is_a?(Date)).to eql(true)
          expect(date.strftime('%Y-%m-%d')).to eql(@date_as_string)
        end

        it 'converts a Ruby Date to an Array [yyyy, mm, dd]' do
          date = @cr.send(:date_to_date_parts, Date.parse(@date_as_string))
          expect(date.is_a?(Array)).to eql(true)
          expect(date).to eql(@date_as_array)
        end
      end

      def date_parts_to_date(parts_array)
        Date.parse(parts_array.join('-'))
      end

      def date_to_date_parts(date)
        date = Date.new(date.to_s)
        [date.year, date.month, date.day]
      end

      describe '#populate_resource' do
        before(:each) do
          allow_any_instance_of(StashEngine::Resource).to receive(:submit_to_solr).and_return(true)
          @cr = Crossref.new(resource: @resource, crossref_json: {
                               'title' => [TITLE],
                               'author' => AUTHOR,
                               'abstract' => ABSTRACT,
                               'funder' => FUNDER,
                               'URL' => URL,
                               'DOI' => DOI,
                               'publisher' => PUBLISHER,
                               'published-online' => { 'date-parts' => PAST_PUBLICATION_DATE }
                             })
        end

        it 'calls the other population methods' do
          @resource = @cr.populate_resource!
          # just basic tests of these items since tested in-depth individually elsewhere
          expect(@resource.title).to eql(TITLE)
          expect(@resource.authors.first.author_first_name).to eql(AUTHOR.first['given'])
          expect(@resource.authors.first.author_last_name).to eql(AUTHOR.first['family'])
          expect(@resource.descriptions.select { |d| d.description_type = 'abstract' }.first.description).to eql(ABSTRACT)
          expect(@resource.contributors.length).to eql(11)
          expect(@resource.related_identifiers.first.related_identifier).to eql(StashDatacite::RelatedIdentifier.standardize_doi(URL))
          expect(@resource.identifier.internal_data.select { |id| id.data_type == 'publicationName' }.first.value).to eql(PUBLISHER)
          doi = @resource.related_identifiers.select { |id| id.related_identifier_type == 'doi' && id.relation_type == 'iscitedby' }
          expect(doi.first&.related_identifier).to end_with(DOI)
        end
      end

      describe '#query_by_doi' do
        it 'returns nil if the resource is nil' do
          expect(Crossref.send(:query_by_doi, resource: nil, doi: '10.123/12345')).to eql(nil)
        end

        it 'returns nil if the DOI is nil' do
          expect(Crossref.send(:query_by_doi, resource: @resource, doi: nil)).to eql(nil)
        end

        it 'returns an initialized Stash::Import::Crossref' do
          expect(Crossref.send(:query_by_doi, resource: @resource, doi: '10.123/12345').is_a?(Crossref)).to eql(true)
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

        it 'returns an initialized Stash::Import::Crossref' do
          allow(Crossref).to receive(:valid_serrano_works_response).and_return(true)
          @resource.title = 'Mu-Opioid Receptor Gene OPRM1 As A Genetic Marker'
          allow(Crossref).to receive(:match_resource_with_crossref_record).and_return([0.5, { 'title' => @resource.title }])
          expect(Crossref.send(:query_by_author_title, resource: @resource).is_a?(Crossref)).to eql(true)
        end
      end

      describe 'Crossref query helper methods' do

        before(:each) do
          identifier = StashEngine::Identifier.create(identifier: 'ABCD')
          identifier.internal_data << StashEngine::InternalDatum.new(data_type: 'publicationISSN', value: '123-456')
          identifier.save
          @resource = StashEngine::Resource.create(title: ' Testing  Again\\', identifier: identifier)
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
            expect(issn).to eql('123-456')
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

      describe '#from_proposed_change' do
        before(:each) do
          allow_any_instance_of(StashEngine::Resource).to receive(:submit_to_solr).and_return(true)
          @params = {
            identifier_id: @resource.identifier.id,
            approved: false,
            authors: AUTHOR.to_json,
            provenance: 'crossref',
            publication_date: Crossref.new(resource: nil, crossref_json: {}).send(:date_parts_to_date, PAST_PUBLICATION_DATE),
            publication_doi: DOI,
            publication_name: PUBLISHER,
            score: 1.0,
            title: TITLE
          }
          @proposed_change = StashEngine::ProposedChange.new(@params)
        end

        it 'properly extracts the data from the ProposedChange' do
          cr = Crossref.from_proposed_change(proposed_change: @proposed_change)
          resource = cr.populate_resource!
          expect(resource.title).to eql(@params[:title])
          expect(resource.identifier.internal_data.select do |id|
                   id.data_type == 'publicationName'
                 end.first.value).to eql(@params[:publication_name])
          doi = resource.related_identifiers.select { |id| id.related_identifier_type == 'doi' && id.relation_type == 'iscitedby' }
          expect(doi.first&.related_identifier).to eql(StashDatacite::RelatedIdentifier.standardize_doi(@params[:publication_doi]))
        end
      end

      describe '#to_proposed_change' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: {
                               'title' => [TITLE],
                               'author' => AUTHOR,
                               'abstract' => ABSTRACT,
                               'funder' => FUNDER,
                               'URL' => URL,
                               'DOI' => DOI,
                               'publisher' => PUBLISHER,
                               'published-online' => { 'date-parts' => FUTURE_PUBLICATION_DATE },
                               'score' => '1.0'
                             })
        end

        it 'initializes a ProposedChange model' do
          proposed_change = @cr.to_proposed_change
          expect(proposed_change.is_a?(StashEngine::ProposedChange)).to eql(true)
          expect(proposed_change.identifier_id).to eql(@resource.identifier_id)
          expect(proposed_change.approved).to eql(false)
          expect(proposed_change.authors).to eql(AUTHOR.to_json)
          expect(proposed_change.provenance).to eql('crossref')
          target_date = @cr.send(:date_parts_to_date, FUTURE_PUBLICATION_DATE).strftime('%Y-%m-%d')
          expect(proposed_change.publication_date.strftime('%Y-%m-%d')).to eql(target_date)
          expect(proposed_change.publication_doi).to eql(DOI)
          expect(proposed_change.publication_name).to eql(PUBLISHER)
          expect(proposed_change.score).to eql(1.0)
          expect(proposed_change.title).to eql(TITLE)
        end
      end
    end
  end
end

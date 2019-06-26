require 'spec_helper'
require 'ostruct'
require 'byebug'
require 'stash/import/crossref'

module Stash
  module Import
    describe Crossref do

      TITLE = 'High-skilled labour mobility in Europe before and after the 2004 enlargement'.freeze
      AUTHOR = [
        { 'ORCID' => 'http://orcid.org/0000-0002-0955-3483', 'given' => 'Julia M.', 'family' => 'Petersen',
          'affiliation' => ['name' => 'Hotel California'] },
        { 'ORCID' => 'http://orcid.org/0000-0002-1212-2233', 'given' => 'Michelangelo', 'family' => 'Snow',
          'affiliation' => ['name' => 'Catalonia'] }
      ].freeze
      ABSTRACT = 'Flip-flop gates must work. In fact, few biologists would disagree with the emulation of expert systems.' \
            ' Our focus in this work is not on whether the partition table and the UNIVAC computer can collude to accomplish this' \
            ' purpose, but rather on presenting an analysis of e-commerce (Newt).'.freeze

      FUNDER = [{ 'name' => 'National Heart, Lung, and Blood Institute',
                  'award' => ['R01-HL30077', 'R01-HL90880', 'R01-HL123526', 'R01-HL085727', 'R01-HL085844', 'P01-HL080101'] },
                { 'name' => 'U.S. Department of Veterans Affairs', 'award' => ['I01 BX000576', 'I01 CX001490'] },
                { 'name' => 'Országos Tudományos Kutatási Alapprogramok', 'award' => ['OTKA101196'] },
                { 'name' => 'California Institute for Regenerative Medicine', 'award' => ['TR3 05626'] },
                { 'name' => 'American Heart Association', 'award' => ['14GRNT20510041'] }].freeze

      URL = 'http://dx.doi.org/10.1073/pnas.1718211115'.freeze

      DOI = '10.1073/pnas.1718211115'.freeze
      PAST_PUBLICATION_DATE = [2018, 01, 01].freeze
      FUTURE_PUBLICATION_DATE = [2035, 01, 01].freeze
      PUBLISHER = 'Ficticious Journal'.freeze

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
        # allow_any_instance_of(Stash::Organization::Ror).to receive(:find_first_by_ror_name).and_return(id: 'abcd', name: 'Hotel California')
        allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)
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
          expect(@resource.authors.first.affiliation.long_name).to eql('Hotel California')
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
          expect(@resource.descriptions.select { |d| d.description_type= 'abstract' }.first.description).to eql(ABSTRACT)
        end

        it "leaves off the abstract when it doesn't exist" do
          @cr = Crossref.new(resource: @resource, crossref_json: {})
          resp = @cr.send(:populate_abstract)
          expect(resp).to eql(nil)
          expect(@resource.descriptions.select { |d| d.description_type= 'abstract' }.length).to eql(0)
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
          cr = Crossref.new(resource: @resource, crossref_json: funders.flatten)
          @cr.send(:populate_funders)
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

      describe '#populate_cited_by' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'URL' => URL })
        end

        it 'takes the DOI URL for the article and turns it into cited_by for this dataset' do
          @cr.send(:populate_cited_by)
          expect(@resource.related_identifiers.any?).to eql(true)
          expect(@resource.related_identifiers.first.related_identifier).to eql(URL)
        end

        it 'ignores blank URLs' do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'URL' => '' })
          resp = @cr.send(:populate_cited_by)
          expect(resp).to eql(nil)
          expect(@resource.related_identifiers.length).to eql(0)
        end
      end

      describe '#populate_doi' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'DOI' => DOI })
        end

        it 'adds the publicationDOI to Internal Datum' do
          @cr.send(:populate_publication_doi)
          expect(@resource.identifier.internal_data.select{ |id| id.data_type == 'publicationDOI' }.first.value).to eql(DOI)
        end

        it 'ignores blank DOIs' do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'DOI' => nil })
          resp = @cr.send(:populate_publication_doi)
          expect(resp).to eql(nil)
          expect(@resource.identifier.internal_data.select{ |id| id.data_type == 'publicationDOI' }.empty?).to eql(true)
        end
      end

      describe '#populate_publication_date' do
        before(:each) do
          allow_any_instance_of(StashEngine::Resource).to receive(:submit_to_solr).and_return(true)
          @cr = Crossref.new(resource: @resource, crossref_json: { 'published-online' => { 'date-parts' => FUTURE_PUBLICATION_DATE } })
        end

        it 'sets the publication_date and publishes adds a `published` curation state when the date has passed' do
          cr = Crossref.new(resource: @resource, crossref_json: { 'published-online' => { 'date-parts' => PAST_PUBLICATION_DATE } })
          cr.send(:populate_publication_date)
          expect(@resource.publication_date).to eql(cr.send(:date_parts_to_date, PAST_PUBLICATION_DATE))
          expect(@resource.current_curation_status).to eql('published')
        end

        it 'sets the publication_date and does NOT add a `published` curation state when the date is in the future' do
          @cr.send(:populate_publication_date)
          expect(@resource.publication_date).to eql(@cr.send(:date_parts_to_date, FUTURE_PUBLICATION_DATE))
          expect(@resource.current_curation_status).to eql('in_progress')
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
          expect(@resource.identifier.internal_data.select{ |id| id.data_type == 'publicationName' }.first.value).to eql(PUBLISHER)
        end

        it 'ignores blank publisher names' do
          @cr = Crossref.new(resource: @resource, crossref_json: { 'publisher' => nil })
          resp = @cr.send(:populate_publication_name)
          expect(resp).to eql(nil)
          expect(@resource.identifier.internal_data.select{ |id| id.data_type == 'publicationName' }.empty?).to eql(true)
        end
      end

      describe '#populate_published_status' do
        before(:each) do
          allow_any_instance_of(StashEngine::Resource).to receive(:submit_to_solr).and_return(true)
          @cr = Crossref.new(resource: @resource, crossref_json: { 'published-online' => { 'date-parts' => PAST_PUBLICATION_DATE } })
        end

        it 'sets the curation state to `published` when the publication date is in the past' do
          @cr.send(:populate_published_status)
          expect(@resource.current_curation_status).to eql('published')
          expect(@resource.current_curation_activity.note).to eql('Crossref reported that the related journal has been published')
        end

        it 'ignores resources that are already published' do
          StashEngine::CurationActivity.create(resource_id: @resource.id, user_id: @user.id, status: 'published', note: 'foo-bar')
          @cr.send(:populate_published_status)
          expect(@resource.current_curation_status).to eql('published')
          expect(@resource.current_curation_activity.note).to eql('foo-bar')
        end

        it 'ignores blank DOIs' do
          cr = Crossref.new(resource: @resource, crossref_json: { 'published-online' => nil })
          cr.send(:populate_published_status)
          expect(@resource.current_curation_status).to eql('in_progress')
        end
      end

      describe 'Date conversions' do
        before(:each) do
          @cr = Crossref.new(resource: @resource, crossref_json: {})
          @date_as_array = [2019, 06, 24]
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
          @resource = @cr.populate_resource
          # just basic tests of these items since tested in-depth individually elsewhere
          expect(@resource.title).to eql(TITLE)
          expect(@resource.authors.first.author_first_name).to eql(AUTHOR.first['given'])
          expect(@resource.authors.first.author_last_name).to eql(AUTHOR.first['family'])
          expect(@resource.descriptions.select { |d| d.description_type= 'abstract' }.first.description).to eql(ABSTRACT)
          expect(@resource.contributors.length).to eql(11)
          expect(@resource.related_identifiers.first.related_identifier).to eql(URL)
          expect(@resource.identifier.internal_data.select{ |id| id.data_type == 'publicationName' }.first.value).to eql(PUBLISHER)
          expect(@resource.identifier.internal_data.select{ |id| id.data_type == 'publicationDOI' }.first.value).to eql(DOI)
          expect(@resource.publication_date).to eql(@cr.send(:date_parts_to_date, PAST_PUBLICATION_DATE))
          expect(@resource.current_curation_status).to eql('published')
          expect(@resource.current_curation_activity.note).to eql('Crossref reported that the related journal has been published')
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
          resource = cr.populate_resource
          auths = JSON.parse(@params[:authors])
          expect(resource.title).to eql(@params[:title])
          expect(resource.identifier.internal_data.select{ |id| id.data_type == 'publicationName' }.first.value).to eql(@params[:publication_name])
          expect(resource.identifier.internal_data.select{ |id| id.data_type == 'publicationDOI' }.first.value).to eql(@params[:publication_doi])
          expect(resource.publication_date).to eql(@params[:publication_date])
          expect(resource.current_curation_status).to eql('published')
          expect(resource.current_curation_activity.note).to eql('Crossref reported that the related journal has been published')
          expect(resource.authors.first.author_first_name).to eql(auths.first['given'])
          expect(resource.authors.first.author_last_name).to eql(auths.first['family'])

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
          expect(proposed_change.publication_date).to eql(@cr.send(:date_parts_to_date, FUTURE_PUBLICATION_DATE))
          expect(proposed_change.publication_doi).to eql(DOI)
          expect(proposed_change.publication_name).to eql(PUBLISHER)
          expect(proposed_change.score).to eql(1.0)
          expect(proposed_change.title).to eql(TITLE)
        end
      end
    end
  end
end

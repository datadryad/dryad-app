require 'spec_helper'
require 'ostruct'
require 'byebug'
require 'stash/import/cross_ref'

module Stash
  module Import
    describe CrossRef do

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
      PAST_PUBLICATION_DATE = ['2018', '01', '01'].freeze
      FUTURE_PUBLICATION_DATE = ['2035', '01', '01'].freeze
      PUBLISHER = 'Ficticious Journal'.freeze

      before(:each) do
        # I don't see any factories here, so just creating a resource manually
        @user = StashEngine::User.create(
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          tenant_id: 'ucop'
        )
        @resource = StashEngine::Resource.create(user_id: @user.id, tenant_id: 'ucop')
        # allow_any_instance_of(Stash::Organization::Ror).to receive(:find_first_by_ror_name).and_return(id: 'abcd', name: 'Hotel California')
        allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)
      end

      describe '#populate_title' do
        before(:each) do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'title' => [TITLE] })
        end

        it 'extracts the title' do
          @cr.send(:populate_title)
          @resource.reload
          expect(@resource.title).to eql(TITLE)
        end

        it "doesn't puke or overwrite with no title" do
          @title = 'meow meow'
          @resource.update(title: @title)
          @cr = CrossRef.new(resource: @resource, serrano_message: {})
          @cr.send(:populate_title)
          @resource.reload
          expect(@resource.title).to eql(@title)
        end

        it "doesn't puke or overwrite with blank title" do
          @title = 'meow meow'
          @resource.update(title: @title)
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'title' => [] })
          resp = @cr.send(:populate_title)
          expect(resp).to eql(nil)
          @resource.reload
          expect(@resource.title).to eql(@title)
        end
      end

      describe '#populate_authors' do
        before(:each) do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'author' => AUTHOR })
        end

        it 'populates names' do
          @cr.send(:populate_authors)
          @resource.reload
          expect(@resource.authors.first.author_first_name).to eql(AUTHOR.first['given'])
          expect(@resource.authors.first.author_last_name).to eql(AUTHOR.first['family'])
          expect(@resource.authors[1].author_first_name).to eql(AUTHOR[1]['given'])
          expect(@resource.authors[1].author_last_name).to eql(AUTHOR[1]['family'])
        end

        it 'populates ORCIDs' do
          @cr.send(:populate_authors)
          @resource.reload
          expect(@resource.authors.first.author_orcid).to eql('0000-0002-0955-3483')
          expect(@resource.authors[1].author_orcid).to eql('0000-0002-1212-2233')
        end

        it 'populates affiliations' do
          @cr.send(:populate_authors)
          @resource.reload
          expect(@resource.authors.first.affiliation.long_name).to eql('Hotel California')
        end

        it 'handles minimal data because lots of stuff is missing metadata' do
          @author_example = [{ 'family' => 'Petersen' }, { 'family' => 'Snow' }]
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'author' => @author_example })
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
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'abstract' => ABSTRACT })
        end

        it 'fills in the abstract when it is supplied' do
          @cr.send(:populate_abstract)
          @resource.reload
          expect(@resource.descriptions.where(description_type: 'abstract').first.description).to eql(ABSTRACT)
        end

        it "leaves off the abstract when it doesn't exist" do
          @cr = CrossRef.new(resource: @resource, serrano_message: {})
          resp = @cr.send(:populate_abstract)
          expect(resp).to eql(nil)
          @resource.reload
          expect(@resource.descriptions.where(description_type: 'abstract').length).to eql(0)
        end
      end

      describe '#populate_funders' do
        before(:each) do
          @funder_example = FUNDER.dup
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'funder' => @funder_example })
        end

        it 'populates a contributor and award for each award number' do
          @cr.send(:populate_funders)
          @resource.reload
          expect(@resource.contributors.length).to eql(11) # one entry for each award
        end

        it 'populates only one award for a contributor without any award number' do
          @funder_example[0] = { 'name' => 'National Heart, Lung, and Blood Institute' }
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'funder' => @funder_example })
          @cr.send(:populate_funders)
          @resource.reload
          expect(@resource.contributors.length).to eql(6)
        end

        it 'removes blank contributor entries before populating' do
          @resource.contributors.create(contributor_name: '', contributor_type: 'funder', award_number: '')
          @cr.send(:populate_funders)
          @resource.reload
          expect(@resource.contributors.length).to eql(11) # not 12, which it would be if the empty one hadn't been removed
        end

        it 'fills in funder name and award number for an individual entry' do
          @cr.send(:populate_funders)
          @resource.reload
          contrib = @resource.contributors.first
          expect(contrib.contributor_name).to eql('National Heart, Lung, and Blood Institute')
          expect(contrib.award_number).to eql('R01-HL30077')
          expect(contrib.contributor_type).to eql('funder')
        end

        it 'handles missing funders' do
          @cr = CrossRef.new(resource: @resource, serrano_message: {})
          @cr.send(:populate_funders)
          @resource.reload
          expect(@resource.contributors.length).to eql(0)
        end
      end

      describe '#populate_cited_by' do
        before(:each) do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'URL' => URL })
        end

        it 'takes the DOI URL for the article and turns it into cited_by for this dataset' do
          @cr.send(:populate_cited_by)
          @resource.reload
          expect(@resource.related_identifiers.first.related_identifier).to eql(URL)
        end

        it 'ignores blank URLs' do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'URL' => '' })
          resp = @cr.send(:populate_cited_by)
          expect(resp).to eql(nil)
          @resource.reload
          expect(@resource.related_identifiers.length).to eql(0)
        end
      end

      describe '#populate_doi' do
        before(:each) do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'DOI': DOI })
        end

        it 'adds the publicationDOI to Internal Datum' do
          @cr.send(:populate_publication_doi)
          expect(@resource.internal_data.where(data_type: 'publicationDOI').any?).to eql(true)
          expect(@resource.internal_data.where(data_type: 'publicationDOI').value).to eql(DOI)
        end

        it 'ignores blank DOIs' do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'DOI': nil })
          resp = @cr.send(:populate_publication_doi)
          expect(resp).to eql(nil)
          expect(@resource.internal_data.where(data_type: 'publicationDOI').empty?).to eql(true)
        end
      end

      describe '#populate_publication_date' do
        before(:each) do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'published-online': { 'date-parts': FUTURE_PUBLICATION_DATE } })
        end

        it 'sets the publication_date' do
          @cr.send(:populate_publication_date)
          expect(@resource.publication_date).to eql(@cr.send(:date_parts_to_date, FUTURE_PUBLICATION_DATE))
        end

        it 'ignores blank Publication Dates' do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'published-online': nil })
          resp = @cr.send(:populate_published_status)
          expect(resp).to eql(nil)
          expect(@resource.publication_date).to eql(nil)
        end
      end

      describe '#populate_publication_name' do
        before(:each) do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'publisher': PUBLISHER })
        end

        it 'adds the publicationName to Internal Datum' do
          @cr.send(:populate_publication_name)
          expect(@resource.internal_data.where(data_type: 'publicationName').any?).to eql(true)
          expect(@resource.internal_data.where(data_type: 'publicationName').value).to eql(PUBLISHER)
        end

        it 'ignores blank Publishers' do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'publisher': '' })
          resp = @cr.send(:populate_publication_name)
          expect(resp).to eql(nil)
          expect(@resource.internal_data.where(data_type: 'publicationName').empty?).to eql(true)
        end

      end

      describe '#populate_published_status' do
        before(:each) do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'published-online': { 'date-parts': PAST_PUBLICATION_DATE } })
        end

        it 'sets the curation state to `published` when the publication date is in the past' do
          resp = @cr.send(:populate_published_status)
          @resource.reload
          expect(@resource.current_curation_status).to eql('published')
          expect(@resource.current_curation_activity.note).to eql('Crossref reported that the related journal has been published')
        end

        it 'does NOT set the curation state to `published` when the publication date is in the future' do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'published-online': { 'date-parts': FUTURE_PUBLICATION_DATE } })
          resp = @cr.send(:populate_published_status)
          expect(resp).to eql(nil)
          @resource.reload
          expect(@resource.current_curation_status).to eql('in_progress')
        end

        it 'ignores resources that are already published' do
          StashEngine::CurationActivity.create(resource_id: @resource.id, user_id: @user.id, status: 'published', note: 'foo-bar')
          @resource.reload
          resp = @cr.send(:populate_published_status)
          expect(resp).to eql(nil)
          @resource.reload
          expect(@resource.current_curation_status).to eql('published')
          expect(@resource.current_curation_activity.note).to eql('foo-bar')
        end

        it 'ignores blank Publication Dates' do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'published-online': { 'date-parts': nil } })
          resp = @cr.send(:populate_published_status)
          expect(resp).to eql(nil)
          @resource.reload
          expect(@resource.current_curation_status).to eql('in_progress')
        end
      end

      describe '#populate' do
        before(:each) do
          @cr = CrossRef.new(resource: @resource, serrano_message:
              { 'title' => [TITLE],
                'author' => AUTHOR,
                'abstract' => ABSTRACT,
                'funder' => FUNDER,
                'URL' => URL })
        end

        it 'calls the other population methods' do
          @cr.populate
          @resource.reload
          # just basic tests of these items since tested in-depth individually elsewhere
          expect(@resource.title).to eql(TITLE)
          expect(@resource.authors.first.author_first_name).to eql(AUTHOR.first['given'])
          expect(@resource.authors.first.author_last_name).to eql(AUTHOR.first['family'])
          expect(@resource.descriptions.where(description_type: 'abstract').first.description).to eql(ABSTRACT)
          expect(@resource.contributors.length).to eql(11)
          expect(@resource.related_identifiers.first.related_identifier).to eql(URL)
        end
      end
    end
  end
end

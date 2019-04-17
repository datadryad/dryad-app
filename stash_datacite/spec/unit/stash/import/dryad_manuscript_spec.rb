require 'spec_helper'
require 'byebug'
require 'stash/import/dryad_manuscript'
require 'fixtures/dryad_manuscript_sim'

module Stash
  module Import
    describe DryadManuscript do

      before(:each) do
        # don't want to emulate full external API, but this should go most of the way by just loading a hash like what is returned

        @user = StashEngine::User.create(
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          tenant_id: 'ucop'
        )
        @resource = StashEngine::Resource.create(user_id: @user.id, tenant_id: 'ucop')
        @big_hash = DryadManuscriptSim.record
        @dm = DryadManuscript.new(resource: @resource, httparty_response: @big_hash)

      end

      describe '#populate_title' do

        it 'extracts the title' do
          @dm.populate_title
          @resource.reload
          expect(@resource.title).to eql(@big_hash['title'])
        end

        it "doesn't puke or overwrite with no title" do
          @big_hash['title'] = nil
          @title = 'meow meow'
          @resource.update(title: @title)
          @dm = DryadManuscript.new(resource: @resource, httparty_response: @big_hash)
          @dm.populate_title
          @resource.reload
          expect(@resource.title).to eql(@title)
        end

        it "doesn't puke or overwrite with blank title" do
          @big_hash['title'] = ''
          @title = 'meow meow'
          @resource.update(title: @title)
          @dm = DryadManuscript.new(resource: @resource, httparty_response: @big_hash)
          @dm.populate_title
          @resource.reload
          expect(@resource.title).to eql(@title)
        end
      end

      describe '#populate_authors' do

        it 'populates author names' do
          @dm.populate_authors
          @resource.reload
          0.upto(3) do |index|
            expect(@resource.authors[index].author_first_name).to eql(@big_hash['authors']['author'][index]['givenNames'])
            expect(@resource.authors[index].author_last_name).to eql(@big_hash['authors']['author'][index]['familyName'])
          end
        end

        it 'populates ORCIDs' do
          @dm.populate_authors
          @resource.reload
          expect(@resource.authors[2].author_orcid).to eql(@big_hash['authors']['author'][2]['identifier'])
        end

        it 'f*cks around with the "correspondingAuthor" to see if it can match and populate a single email' do
          @dm.populate_authors
          @resource.reload
          expect(@resource.authors[0].author_email).to eql(@big_hash['correspondingAuthor']['email'])
        end

        it "doesn't populate correspondingAuthor if the name doesn't match" do
          @big_hash['authors']['author'][0]['givenNames'] = 'Rotunda'
          @dm = DryadManuscript.new(resource: @resource, httparty_response: @big_hash)
          @dm.populate_authors
          @resource.reload
          expect(@resource.authors[0].author_email).to be_nil
        end

        it 'ignores crappy-ass garbage tagged on in the email field' do
          @big_hash['correspondingAuthor']['email'] = 'grogolia@escape.example.com my institution is awesome and I talk about it in here'
          @dm = DryadManuscript.new(resource: @resource, httparty_response: @big_hash)
          @dm.populate_authors
          @resource.reload
          expect(@resource.authors[0].author_email).to eql('grogolia@escape.example.com')
        end
      end

      describe '#populate_abstract' do

        xit 'fills in the abstract when it is supplied' do
          @cr.populate_abstract
          @resource.reload
          expect(@resource.descriptions.where(description_type: 'abstract').first.description).to eql(ABSTRACT)
        end

        xit "leaves off the abstract when it doesn't exist" do
          @cr = CrossRef.new(resource: @resource, serrano_message: {})
          @cr.populate_abstract
          @resource.reload
          expect(@resource.descriptions.where(description_type: 'abstract').length).to eql(0)
        end
      end

      describe '#populate_funders' do

        xit 'populates a contributor and award for each award number' do
          @cr.populate_funders
          @resource.reload
          expect(@resource.contributors.length).to eql(11) # one entry for each award
        end

        xit 'populates only one award for a contributor without any award number' do
          @funder_example[0] = { 'name' => 'National Heart, Lung, and Blood Institute' }
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'funder' => @funder_example })
          @cr.populate_funders
          @resource.reload
          expect(@resource.contributors.length).to eql(6)
        end

        xit 'removes blank contributor entries before populating' do
          @resource.contributors.create(contributor_name: '', contributor_type: 'funder', award_number: '')
          @cr.populate_funders
          @resource.reload
          expect(@resource.contributors.length).to eql(11) # not 12, which it would be if the empty one hadn't been removed
        end

        xit 'fills in funder name and award number for an individual entry' do
          @cr.populate_funders
          @resource.reload
          contrib = @resource.contributors.first
          expect(contrib.contributor_name).to eql('National Heart, Lung, and Blood Institute')
          expect(contrib.award_number).to eql('R01-HL30077')
          expect(contrib.contributor_type).to eql('funder')
        end

        xit 'handles missing funders' do
          @cr = CrossRef.new(resource: @resource, serrano_message: {})
          @cr.populate_funders
          @resource.reload
          expect(@resource.contributors.length).to eql(0)
        end
      end

      describe '#populate_cited_by' do

        xit 'takes the DOI URL for the article and turns it into cited_by for this dataset' do
          @cr.populate_cited_by
          @resource.reload
          expect(@resource.related_identifiers.first.related_identifier).to eql(URL)
        end

        xit 'ignores blank URLs' do
          @cr = CrossRef.new(resource: @resource, serrano_message: { 'URL' => '' })
          @cr.populate_cited_by
          @resource.reload
          expect(@resource.related_identifiers.length).to eql(0)
        end
      end

      describe '#populate' do

        xit 'calls the other population methods' do
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

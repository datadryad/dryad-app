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
          @big_hash['authors']['author'].each_with_index do |hash_author, index|
            expect(@resource.authors[index].author_first_name).to eql(hash_author['givenNames'])
            expect(@resource.authors[index].author_last_name).to eql(hash_author['familyName'])
          end
        end

        it 'populates ORCIDs' do
          @dm.populate_authors
          @resource.reload
          expect(@resource.authors[2].author_orcid).to eql(@big_hash['authors']['author'][2]['identifier'])
        end

        it 'watches the "correspondingAuthor" to see if it can match and populate a single email' do
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

        it 'ignores crappy-ass garbage tacked into the email field' do
          @big_hash['correspondingAuthor']['email'] = 'grogolia@escape.example.com my institution is awesome and I talk about it in here'
          @dm = DryadManuscript.new(resource: @resource, httparty_response: @big_hash)
          @dm.populate_authors
          @resource.reload
          expect(@resource.authors[0].author_email).to eql('grogolia@escape.example.com')
        end
      end

      describe '#populate_abstract' do

        it 'fills in the abstract when it is supplied' do
          @dm.populate_abstract
          @resource.reload
          expect(@resource.descriptions.where(description_type: 'abstract').first.description).to eql(@big_hash['abstract'])
        end

        it "leaves off the abstract when it doesn't exist" do
          @big_hash['abstract'] = nil
          @dm = DryadManuscript.new(resource: @resource, httparty_response: @big_hash)
          @dm.populate_abstract
          @resource.reload
          expect(@resource.descriptions.where(description_type: 'abstract').length).to eql(0)
        end
      end

      describe '#populate_keywords' do
        it 'populates the keywords supplied' do
          @dm.populate_keywords
          @resource.reload
          @big_hash['keywords'].each_with_index do |hash_kw, index|
            expect(@resource.subjects[index].subject).to eql(hash_kw)
          end
        end

        it 'ignores missing keywords' do
          @big_hash['keywords'] = nil
          @dm = DryadManuscript.new(resource: @resource, httparty_response: @big_hash)
          @dm.populate_keywords
          @resource.reload
          expect(@resource.subjects.length).to eq(0)
        end
      end

      describe '#populate' do
        it 'calls the other population methods' do
          @dm.populate
          @resource.reload
          # just superficial tests of these items since tested in-depth elsewhere in individual unit tests for specific methods
          expect(@resource.title).to eql(@big_hash['title'])
          expect(@resource.authors.length).to eq(@big_hash['authors']['author'].length)
          expect(@resource.descriptions.where(description_type: 'abstract').first.description).to eql(@big_hash['abstract'])
          expect(@resource.subjects.length).to eq(@big_hash['keywords'].length)
        end
      end
    end
  end
end

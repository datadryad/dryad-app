require 'json'

module Stash
  module Import
    describe Datacite do
      let(:json) { JSON.parse(File.read('spec/data/datacite-metadata1.json')).dig('data', 'attributes') }
      let(:resource) { create(:resource, :blank) }
      let(:import) { Datacite.new(resource: resource, json: json) }

      describe '#populate_abstract' do
        it 'fills in the abstract' do
          import.send(:populate_abstract)
          expect(resource.descriptions.length).to eq(1)
          expect(resource.descriptions.last.description).to eq('This is just some text content for an abstract.')
        end
      end

      describe '#populate_authors' do
        before(:each) { allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil) }

        it 'adds authors and affiliations' do
          import.send(:populate_authors)
          expect(resource.authors.length).to eq(2)
          expect(resource.authors.first.name).to eq('Test Person')
          expect(resource.authors.last.name).to eq('Test Organization')
          resource.authors.first.reload
          expect(resource.authors.first.affiliations.first.long_name).to eq('A Test Place')
        end
      end

      describe '#populate_article_type' do
        it 'adds a related work' do
          import.send(:populate_article_type, article_type: 'primary_article')
          expect(resource.identifier.publication_article_doi).to eq('https://doi.org/10.6071/m3rp49')
        end
      end

      describe '#populate_funders' do
        it 'adds funding' do
          import.send(:populate_funders)
          expect(resource.contributors.length).to eq(1)
          expect(resource.contributors.first.contributor_name).to eq('Rhodes Trust')
        end
      end

      describe '#populate_publication_name' do
        it 'adds the resource publication' do
          import.send(:populate_publication_name)
          expect(resource.resource_publication.publication_name).to eq('Test Server')
        end
      end

      describe '#populate_title' do
        it 'fills in the title' do
          import.send(:populate_title)
          expect(resource.title).to eq('Test title for a preprint or article')
        end
      end

      describe '#populate_subjects' do
        it 'adds subjects' do
          import.send(:populate_subjects)
          expect(resource.subjects.length).to eq(2)
          expect(resource.subjects.first.subject).to eq('Test')
          expect(resource.subjects.last.subject).to eq('Testing')
        end
      end

      describe '#populate_resource!' do
        before(:each) { allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil) }

        it 'calls the other population methods' do
          import.send(:populate_resource!)
          expect(resource.title).to eq('Test title for a preprint or article')
          expect(resource.authors.length).to eq(2)
          expect(resource.authors.first.name).to eq('Test Person')
          expect(resource.authors.last.name).to eq('Test Organization')
          expect(resource.authors.first.affiliations.first.long_name).to eq('A Test Place')
          expect(resource.descriptions.length).to eq(1)
          expect(resource.descriptions.last.description).to eq('This is just some text content for an abstract.')
          expect(resource.subjects.first.subject).to eq('Test')
          expect(resource.subjects.last.subject).to eq('Testing')
          expect(resource.identifier.publication_article_doi).to eq('https://doi.org/10.6071/m3rp49')
          expect(resource.resource_publication.publication_name).to eq('Test Server')
          expect(resource.contributors.first.contributor_name).to eq('Rhodes Trust')
        end
      end
    end
  end
end

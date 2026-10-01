module Stash
  module Import
    describe ScholarOne do
      let(:json) { JSON.parse(File.read('spec/data/scholar_one_metadata.json')) }
      let(:authors_json) { JSON.parse(File.read('spec/data/scholar_one_authors_metadata.json')) }
      let(:manuscript_number) { json['submissionId'] }
      let(:resource) { create(:resource, :blank) }
      let(:journal) { create(:journal) }
      let(:import) { ScholarOne.new(resource: resource, manuscript_number: manuscript_number, journal: journal) }

      before do
        allow_any_instance_of(Integrations::ScholarOne).to receive(:manuscript_metadata).and_return(json)
        allow_any_instance_of(Integrations::ScholarOne).to receive(:authors_metadata).and_return(authors_json)
      end

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
          resource.authors.each(&:reload)
          expect(resource.authors.length).to eq(2)
          expect(resource.authors.first.attributes.slice(*%w[author_first_name author_last_name author_email]))
            .to eq({ 'author_email' => 'test.person@test.com', 'author_first_name' => 'Test', 'author_last_name' => 'Person' })
          expect(resource.authors.last.attributes.slice(*%w[author_first_name author_last_name author_email]))
            .to eq({ 'author_email' => 'second.person@test.com', 'author_first_name' => 'Test', 'author_last_name' => 'Second' })
          expect(resource.authors.first.affiliations.first.long_name).to eq('Hello Pharmacie SAS')
          expect(resource.authors.last.affiliations.first.long_name).to eq('Ministry of Education, Youth and Sport')
        end
      end

      describe '#populate_funders' do
        it 'adds funding' do
          import.send(:populate_funders)
          expect(resource.contributors.length).to eq(1)
          expect(resource.contributors.first.contributor_name).to eq('National Institute of Mental Health')
        end
      end

      describe '#populate_publication_name' do
        it 'adds the resource publication' do
          import.send(:populate_publication_name)
          expect(resource.resource_publication.publication_name).to eq('Support Demo Plus')
          expect(resource.resource_publication.publication_issn).to eq('5678-1234')
        end
      end

      describe '#populate_title' do
        it 'fills in the title' do
          import.send(:populate_title)
          expect(resource.title).to eq('Test title of the manuscript')
        end
      end

      describe '#populate_subjects' do
        it 'adds subjects' do
          import.send(:populate_subjects)
          expect(resource.subjects.length).to eq(2)
          expect(resource.subjects.first.subject).to eq('Education, Distance')
          expect(resource.subjects.last.subject).to eq('Test')
        end
      end

      describe '#populate_research_domains' do
        it 'does not add custom research domain' do
          import.send(:populate_research_domains)
          expect(resource.subjects.length).to eq(0)
        end
      end

      describe '#populate' do
        before(:each) { allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil) }

        it 'calls the other population methods' do
          import.send(:populate)
          expect(resource.title).to eq('Test title of the manuscript')
          expect(resource.authors.length).to eq(2)
          expect(resource.authors.first.name).to eq('Test Second')
          expect(resource.authors.last.name).to eq('Test Person')
          expect(resource.authors.first.affiliations.first.long_name).to eq('Ministry of Education, Youth and Sport')
          expect(resource.descriptions.length).to eq(1)
          expect(resource.descriptions.last.description).to eq('This is just some text content for an abstract.')
          expect(resource.subjects.first.subject).to eq('Education, Distance')
          expect(resource.subjects.last.subject).to eq('Test')
          expect(resource.resource_publication.publication_name).to eq('Support Demo Plus')
          expect(resource.resource_publication.publication_issn).to eq('5678-1234')
          expect(resource.contributors.first.contributor_name).to eq('National Institute of Mental Health')
        end
      end
    end
  end
end

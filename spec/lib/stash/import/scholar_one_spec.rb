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
        journal.reload
      end

      describe '#populate' do
        context 'when the integration is not configured' do
          it 'does not import anything' do
            expect(import.populate).to be_nil
            expect(resource.title).to be_blank
          end
        end

        context 'when the integration is configured' do
          let!(:integration) { create(:external_integration, integration: 'scholarone', integrator: journal) }
          before(:each) do
            allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)
          end

          it 'calls the other population methods' do
            expect(import.populate).to be_truthy

            # #polulate_title
            expect(resource.title).to eq('Test title of the manuscript')

            # #populate_authors
            resource.authors.each(&:reload)
            expect(resource.authors.length).to eq(2)
            expect(resource.authors.first.name).to eq('Test Second')
            expect(resource.authors.last.name).to eq('Test Person')
            expect(resource.authors.first.affiliations.first.long_name).to eq('Ministry of Education, Youth and Sport')
            expect(resource.authors.length).to eq(2)
            expect(resource.authors.first.attributes.slice(*%w[author_first_name author_last_name author_email]))
              .to eq({ 'author_email' => 'second.person@test.com', 'author_first_name' => 'Test', 'author_last_name' => 'Second' })
            expect(resource.authors.last.attributes.slice(*%w[author_first_name author_last_name author_email]))
              .to eq({ 'author_email' => 'test.person@test.com', 'author_first_name' => 'Test', 'author_last_name' => 'Person' })
            expect(resource.authors.first.affiliations.first.long_name).to eq('Ministry of Education, Youth and Sport')
            expect(resource.authors.last.affiliations.first.long_name).to eq('Hello Pharmacie SAS')

            # populate_abstract
            expect(resource.descriptions.length).to eq(1)
            expect(resource.descriptions.last.description).to eq('This is just some text content for an abstract.')

            # #populate_funders
            expect(resource.contributors.length).to eq(1)
            expect(resource.contributors.first.contributor_name).to eq('National Institute of Mental Health')

            # #populate_publication_name
            expect(resource.resource_publication.publication_name).to eq('Support Demo Plus')
            expect(resource.resource_publication.publication_issn).to eq('5678-1234')

            # #populate_subjects
            expect(resource.subjects.length).to eq(2)
            expect(resource.subjects.first.subject).to eq('Education, Distance')
            expect(resource.subjects.last.subject).to eq('Test')
          end
        end
      end
    end
  end
end

describe RelatedIdentifierService do
  include Mocks::Datacite

  let(:resource) { create(:resource_published) }
  let(:related_identifier) { create(:related_identifier, resource: resource) }
  let(:subject) { RelatedIdentifierService.new(resource) }
  let(:note_text) { '<p>The <a href="https://doi.org/10.1098/rsif.2017.0031">primary article associated with this dataset</a> has been retracted.</p>' }

  before do
    Sidekiq::Testing.inline!
    related_identifier.reload
    mock_datacite!
    stub_request(:get, 'https://api.crossref.org/works/10.1098%2Frsif.2017.0030')
      .to_return(status: 200,
                 body: File.new(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'crossref_response.json')),
                 headers: {})

    stub_request(:get, 'https://api.crossref.org/works/10.1098%2Frsif.2017.0031')
      .to_return(status: 200,
                 body: File.new(File.join(Rails.root, 'spec', 'fixtures', 'http_responses', 'crossref_response_retracted.json')),
                 headers: {})

  end

  describe '#initialize' do
    it 'sets proper attributes' do
      expect(subject.resource).to eq(resource)
    end
  end

  context 'primary articles' do
    let(:related_identifier) { create(:related_identifier, :publication_doi, related_identifier: 'https://doi.org/10.1098/rsif.2017.0030', resource: resource) }

    describe '#initialize' do
      it 'sets proper attributes' do
        expect(subject.resource).to eq(resource)
        expect(subject.primary_article).to eq(related_identifier)
      end
    end

    describe 'actions changing primary article values' do
      it 'adds no note for a normal primary article' do
        subject.process
        desc = resource.descriptions.find_by(description_type: 'concern')
        expect(desc).to be_nil
      end

      it 'adds a note when the value is changed to a retracted article' do
        related_identifier.update(related_identifier: 'https://doi.org/10.1098/rsif.2017.0031')
        subject.process
        desc = resource.descriptions.find_by(description_type: 'concern')
        expect(desc).not_to be_nil
        expect(desc.description).to eq(note_text)
      end
    end
  end

  context 'retracted articles' do
    let(:related_identifier) { create(:related_identifier, :publication_doi, related_identifier: 'https://doi.org/10.1098/rsif.2017.0031', resource: resource) }

    describe '#initialize' do
      it 'sets proper attributes' do
        expect(subject.resource).to eq(resource)
        expect(subject.primary_article).to eq(related_identifier)
      end
    end

    describe 'actions changing primary article values' do
      before do
        subject.process
        desc = resource.descriptions.find_by(description_type: 'concern')
        expect(desc).not_to be_nil
        expect(desc.description).to eq(note_text)
      end

      it 'removes the note when the retracted article identifier is changed' do
        related_identifier.update(related_identifier: 'https://doi.org/10.1098/rsif.2017.0030')
        subject.process
        desc = resource.descriptions.find_by(description_type: 'concern')
        expect(desc).to be_nil
      end

      it 'removes the note when the retracted article is no longer primary' do
        related_identifier.update(work_type: :article)
        RelatedIdentifierService.new(resource).process
        desc = resource.descriptions.find_by(description_type: 'concern')
        expect(desc).to be_nil
      end

      it 'removes the note when the retracted article is removed' do
        related_identifier.destroy
        RelatedIdentifierService.new(resource).process
        desc = resource.descriptions.find_by(description_type: 'concern')
        expect(desc).to be_nil
      end
    end
  end

  after { Sidekiq::Testing.fake! }

end

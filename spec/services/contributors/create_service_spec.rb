module Contributors
  RSpec.describe CreateService do
    let(:identifier) { create(:identifier) }
    let(:resource) { create(:resource, identifier: identifier) }
    let(:contributor_type) { 'sponsor' }
    let(:ror_id) { NIH_ROR }
    let(:valid_attrs) do
      { contributor_type: 'funder', award_number: '12345', identifier_type: 'ror', name_identifier_id: 'ror_id' }
    end
    let(:invalid_attrs) do
      { contributor_type: 'something_else' }
    end

    before { resource.contributors.delete_all }

    subject { described_class.new(resource) }

    describe '#initialize' do
      it 'sets resource' do
        service = subject
        expect(service.resource).to eq resource
      end
    end

    describe '#create' do
      context 'with valid attributes' do
        it 'does not creates a new contributor' do
          expect { subject.create(invalid_attrs) }.to raise_exception(ArgumentError, "'something_else' is not a valid contributor_type")
        end
      end

      context 'with valid attributes' do
        it 'creates a new contributor' do
          expect { subject.create(valid_attrs) }.to change { resource.contributors.count }.by(1)
        end

        it 'does not create doubled contributor records' do
          expect do
            subject.create(valid_attrs)
            subject.create(valid_attrs)
          end.to change { resource.contributors.count }.by(1)
        end

        context 'with sponsor' do
          before { create(:contributor, contributor_type: 'funder', name_identifier_id: '0', resource_id: resource.id) }

          it 'does not deletes blank UI funder' do
            new_attrs = valid_attrs.merge({ contributor_type: 'sponsor' })
            expect { subject.create(new_attrs) }.to change { resource.contributors.count }.by(1)
            expect(resource.contributors.count).to eq(2)
          end
        end

        context 'with funder type' do
          before do
            create(:contributor, contributor_type: 'funder', name_identifier_id: '0', resource_id: resource.id)
            resource.reload
          end

          it 'deletes blank UI funder' do
            new_attrs = valid_attrs.merge({ contributor_type: 'funder' })

            expect(resource.contributors.count).to eq(1)
            expect(resource.contributors.last.name_identifier_id).to eq('0')
            expect { subject.create(new_attrs) }.not_to(change { resource.contributors.count })
            expect(resource.contributors.count).to eq(1)
            expect(resource.contributors.last.name_identifier_id).to eq('ror_id')
          end
        end
      end
    end

    describe '#create_funder_from_pubmed' do
      context 'when pubmed ID is already in DB' do
        context 'when pubmedID is valid' do
          before do
            create(:internal_datum, data_type: 'pubmedID', value: '123456', identifier_id: identifier.id)

          end

          it 'creates a new contributor' do
            expect_any_instance_of(AwardMetadataService).to receive(:populate_from_api).and_return(true)

            VCR.use_cassette('pubmed_api/fetch_by_pim_id_valid_results') do
              expect { subject.create_funder_from_pubmed(NIH_ROR) }.to change { resource.contributors.count }.by(1)
            end
          end
        end

        context 'when pubmedID is not found' do
          before { create(:internal_datum, data_type: 'pubmedID', value: '123456', identifier_id: identifier.id) }

          it 'creates a new contributor' do
            expect(AwardMetadataService).not_to receive(:new)

            VCR.use_cassette('pubmed_api/fetch_by_pim_id_no_results') do
              expect { subject.create_funder_from_pubmed(NIH_ROR) }.not_to(change { resource.contributors.count })
            end
          end
        end
      end

      context 'when pubmed ID is not in DB' do
        before do
          identifier.internal_data.destroy_all
          identifier.reload
        end

        context 'when there is an primary article' do
          context 'when article DOI is not found' do
            before do
              create(:related_identifier, :publication_doi, resource: resource, related_identifier: 'not_found')
            end

            it 'does not create any contributor' do
              expect(AwardMetadataService).not_to receive(:new)

              VCR.use_cassette('pubmed_api/fetch_pim_id_no_results') do
                expect { subject.create_funder_from_pubmed(ror_id) }.not_to(change { resource.contributors.count })
              end
            end
          end

          context 'when article DOI is found' do
            before do
              create(:related_identifier, :publication_doi, resource: resource, related_identifier: 'valid_doi')
            end

            it 'calls contributor #create_with_pubmed_id with proper info' do
              VCR.use_cassette('pubmed_api/fetch_pim_id_one_result') do
                expect(subject).to receive(:create_with_pubmed_id).with('123456', ror_id)
                subject.create_funder_from_pubmed(ror_id)
              end
            end

            it 'calls saves pubmedId entry' do
              VCR.use_cassette('pubmed_api/fetch_pim_id_one_result') do
                expect { subject.create_funder_from_pubmed(ror_id) }.to change { identifier.internal_data.count }.by(1)
                expect(identifier.reload.internal_data.where(data_type: 'pubmedID').first.value).to eq('123456')
              end
            end
          end
        end

        context 'when there is no primary article' do
          it 'creates a new contributor' do
            expect(Integrations::PubMed).not_to receive(:new)
            expect(AwardMetadataService).not_to receive(:new)
            expect(subject).not_to receive(:create_with_pubmed_id)

            expect { subject.create_funder_from_pubmed(ror_id) }.not_to(change { identifier.internal_data.count })
          end
        end
      end
    end
  end
end

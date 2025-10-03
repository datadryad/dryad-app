describe ResourceMetadataService do
  let(:identifier) { create(:identifier) }
  let!(:resource) { create(:resource, identifier: identifier) }

  before do
    resource.contributors.destroy_all
  end

  describe '#initialize' do
    it 'sets the proper attributes' do
      service = described_class.new(resource)
      expect(service.resource).to eq(resource)
    end
  end

  describe '#recurate_awards' do
    subject { described_class.new(resource).recurate_awards }

    context 'when resource contributor is a funder' do
      context 'when funder has an award number' do
        context 'when funder has api integration' do
          let!(:funder) { create(:contributor, resource: resource, award_number: 'R01HD113192', name_identifier_id: NIH_ROR) }

          it 'calls AwardMetadataService for contributor' do
            expect(AwardMetadataService).to receive_message_chain(:new, :populate_from_api).with(funder).with(no_args).and_return(nil)
            subject
          end
        end

        context 'when funder is not part of any integration' do
          let!(:funder) { create(:contributor, resource: resource, award_number: 'R01HD113192', name_identifier_id: 'other_ror') }

          it 'does not call AwardMetadataService for contributor' do
            expect(AwardMetadataService).not_to receive(:new)
            subject
          end
        end
      end

      context 'when funder has no award number' do
        let!(:funder) { create(:contributor, resource: resource, award_number: '', name_identifier_id: NIH_ROR) }

        it 'does not call AwardMetadataService for contributor' do
          expect(AwardMetadataService).not_to receive(:new)
          subject
        end
      end
    end

    context 'when resource contributor is a funder' do
      let!(:sponsor) { create(:contributor, resource: resource, contributor_type: 'sponsor', award_number: '12345', name_identifier_id: 'https://ror.org/028rq5v79') }

      it 'does not call AwardMetadataService for contributor' do
        expect(AwardMetadataService).not_to receive(:new)
        subject
      end
    end
  end
end

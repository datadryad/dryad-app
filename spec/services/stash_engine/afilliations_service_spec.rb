describe AffiliationsService do

  let!(:aff_with_ror) { create(:affiliation, long_name: 'First affiliation') }
  let!(:aff_without_ror_1) { create(:affiliation, long_name: 'First affiliation', ror_id: nil) }
  let!(:aff_without_ror_2) { create(:affiliation, long_name: 'First affiliation', ror_id: nil) }
  let!(:aff_with_different_name_1) { create(:affiliation, long_name: 'Second affiliation', ror_id: nil) }
  let!(:aff_with_different_name_2) { create(:affiliation, long_name: 'Second affiliation', ror_id: nil) }
  let!(:aff_with_different_name_and_ror_1) { create(:affiliation, long_name: 'Third affiliation') }
  let!(:aff_with_different_name_and_ror_2) { create(:affiliation, long_name: 'Third affiliation') }
  let(:main_affiliation) { aff_with_ror }

  let!(:author_1) { create(:author, affiliations: [aff_with_ror]) }
  let!(:author_2) { create(:author, affiliations: [aff_without_ror_1, aff_with_different_name_1]) }
  let!(:author_3) { create(:author, affiliations: [aff_without_ror_1, aff_with_different_name_1, aff_without_ror_2]) }
  let!(:author_4) { create(:author, affiliations: [aff_without_ror_1, aff_with_different_name_1, aff_with_different_name_and_ror_1]) }

  subject { described_class.new(main_affiliation) }

  describe '#initialize' do
    it 'sets the main affiliation' do
      expect(subject.affiliation).to eq(aff_with_ror)
    end
  end

  describe 'if duplicates exist' do
    it 'deletes affiliations' do
      expect do
        subject.make_uniq
        expect(StashDatacite::Affiliation.where(long_name: main_affiliation.long_name).count).to eq(1)
      end.to change { StashDatacite::Affiliation.count }.by(-2)
    end
  end

  describe '#make_unique' do
    subject { described_class.new(main_affiliation).make_uniq }

    before { subject }

    context 'when the main affiliation has a ror' do
      it 'updates authors' do
        expect(author_1.reload.affiliations).to match_array([aff_with_ror])
        expect(author_2.reload.affiliations).to match_array([aff_with_ror, aff_with_different_name_1])

        # does not double the affiliation relation
        expect(author_3.reload.affiliations).to match_array([aff_with_ror, aff_with_different_name_1])
      end
    end

    context 'when the all similar affiliation have a ror' do
      let(:main_affiliation) { aff_with_different_name_and_ror_2 }

      it 'updates authors' do
        expect(author_4.reload.affiliations).to match_array([aff_without_ror_1, aff_with_different_name_1, aff_with_different_name_and_ror_2])
        # does not affect other authors
        expect(author_2.reload.affiliations).to match_array([aff_without_ror_1, aff_with_different_name_1])
        expect(author_3.reload.affiliations).to match_array([aff_without_ror_1, aff_with_different_name_1, aff_without_ror_2])
      end
    end

    context 'when the main affiliation does not have a ror' do
      context 'same name affiliation with ror exists' do
        let(:main_affiliation) { aff_without_ror_2 }

        it 'updates authors with the affiliation that has a ror' do
          expect(author_1.reload.affiliations).to match_array([aff_with_ror])
          expect(author_2.reload.affiliations).to match_array([aff_with_ror, aff_with_different_name_1])
          expect(author_3.reload.affiliations).to match_array([aff_with_ror, aff_with_different_name_1])
        end
      end

      context 'same name affiliation with ror does not exist' do
        let(:main_affiliation) { aff_with_different_name_2 }

        it 'updates authors with given affiliation' do
          expect(author_1.reload.affiliations).to match_array([aff_with_ror])
          expect(author_2.reload.affiliations).to match_array([aff_without_ror_1, aff_with_different_name_2])
          expect(author_3.reload.affiliations).to match_array([aff_without_ror_1, aff_with_different_name_2, aff_without_ror_2])
          expect(author_4.reload.affiliations).to match_array([aff_without_ror_1, aff_with_different_name_2, aff_with_different_name_and_ror_1])
        end
      end
    end
  end

  describe '#affiliations_with_same_name' do
    subject { described_class.new(main_affiliation).affiliations_with_same_name }

    it 'returns all affiliations with the same name' do
      expect(subject).to match_array([aff_with_ror, aff_without_ror_1, aff_without_ror_2])
    end

    it 'does not run the query twice' do
      expect(StashDatacite::Affiliation).to receive(:where).once
      subject
      subject
    end
  end

  describe '#base_affiliation' do
    subject { described_class.new(main_affiliation).send(:base_affiliation) }

    context 'when the main affiliation has a ror' do
      it 'returns main affiliation' do
        expect(subject).to eq(aff_with_ror)
      end
    end

    context 'when the all similar affiliation have a ror' do
      let(:main_affiliation) { aff_with_different_name_and_ror_2 }

      it 'returns main affiliation' do
        expect(subject).to eq(aff_with_different_name_and_ror_2)
      end
    end

    context 'when the main affiliation does not have a ror' do
      context 'same name affiliation with ror exists' do
        let(:main_affiliation) { aff_without_ror_2 }

        it 'returns affiliation with ror' do
          expect(subject).to eq(aff_with_ror)
        end
      end

      context 'same name affiliation with ror does not exist' do
        let(:main_affiliation) { aff_with_different_name_1 }

        it 'returns the same instance' do
          expect(subject).to eq(aff_with_different_name_1)
        end
      end
    end
  end
end

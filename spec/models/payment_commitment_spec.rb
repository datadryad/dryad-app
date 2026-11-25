# == Schema Information
#
# Table name: payment_commitments
#
#  id                   :bigint           not null, primary key
#  asf                  :float(24)
#  asf_due              :float(24)
#  asf_prepaid          :float(24)
#  batch                :string(191)
#  commitment_years     :integer
#  consortium_discount  :float(24)
#  covers_ldf           :boolean
#  deleted_at           :datetime
#  dpc_carryover        :integer
#  dpc_commitment       :integer
#  dpc_commitment_price :float(24)
#  ldf_carryover        :float(24)
#  ldf_commitment       :float(24)
#  ldf_size_limit       :integer
#  payment_plan         :string(191)
#  period_discount      :float(24)
#  sponsor_type         :string(191)
#  start_date           :date
#  update_notes         :json
#  year                 :integer
#  year_index           :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  sponsor_id           :string(191)
#
# Indexes
#
#  index_payment_commitments_on_sponsor_id_and_sponsor_type  (sponsor_id,sponsor_type)
#
describe PaymentCommitment, type: :model do
  let(:sponsor) { create(:journal_organization) }
  let!(:payment_commitment) { create(:payment_commitment, sponsor: sponsor, year: 2026) }

  describe '#destroy' do
    it_should_behave_like 'soft delete record', :payment_commitment
  end

  describe 'associations' do
    it { is_expected.to belong_to(:sponsor) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:note) }

    context 'year uniqueness validation' do
      it 'validates uniqueness scoped to sponsor with deleted_at condition' do
        new_commitment = build(:payment_commitment, sponsor: sponsor, year: 2026)
        expect(new_commitment).not_to be_valid
        expect(new_commitment.errors[:year]).to include('has already been taken')
      end

      it 'allows duplicate year for same sponsor if one is deleted' do
        payment_commitment.destroy

        new_commitment = build(:payment_commitment, sponsor: sponsor, year: 2026)
        expect(new_commitment).to be_valid
      end

      it 'allows duplicate year for different sponsors' do
        other_sponsor = create(:journal_organization)

        new_commitment = build(:payment_commitment, sponsor: other_sponsor, year: 2026)
        expect(new_commitment).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe '#set_note' do
      it 'should add the current time and note to update_notes' do
        current_time = Time.current
        payment_commitment.note = 'Test note'
        payment_commitment.save
        expect(payment_commitment.update_notes).to include(current_time.to_s => 'Test note')
      end
    end
  end
end

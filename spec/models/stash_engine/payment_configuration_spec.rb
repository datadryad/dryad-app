# == Schema Information
#
# Table name: payment_configurations
#
#  id                     :bigint           not null, primary key
#  covers_ldf             :boolean
#  ldf_limit              :integer
#  ldf_limit_notification :text(65535)
#  partner_type           :string(191)
#  payment_plan           :integer
#  submitter_contact      :text(65535)
#  yearly_ldf_limit       :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  partner_id             :string(191)
#

# NOTE: ldf_limit stores the tier number and not an actual limit size
RSpec.describe PaymentConfiguration, type: :model do
  let(:tenant) { create(:tenant) }
  subject(:configuration) { create(:payment_configuration, partner: tenant) }

  describe 'validations' do
    describe 'submitter_contact' do
      it 'allows a blank submitter contact' do
        configuration.submitter_contact = ''
        expect(configuration).to be_valid
      end

      it 'allows a valid submitter contact' do
        configuration.submitter_contact = 'user@example.com'
        expect(configuration).to be_valid
      end

      it 'rejects an invalid submitter contact' do
        configuration.submitter_contact = 'invalid-email'

        expect(configuration).not_to be_valid
        expect(configuration.errors[:submitter_contact]).to include('invalid-email is not a valid email address')
      end
    end

  end

  describe 'payment_plan enum' do
    it 'defines the expected values' do
      expect(described_class.payment_plans).to eq(
                                                 'SUBSCRIPTION' => 1,
                                                 'PREPAID' => 2,
                                                 'DEFERRED' => 3,
                                                 'TIERED' => 4,
                                                 '2025' => 5
                                               )
    end
  end

  describe '#valid_payer?' do
    it 'returns true for set payment_plan' do
      configuration.payment_plan = '2025'
      expect(configuration.valid_payer?).to be_truthy
    end

    it 'returns false for no payment_plan set' do
      configuration.payment_plan = nil
      expect(configuration.valid_payer?).to be_falsey
    end
  end

  describe '#covers_dpc?' do
    it 'returns true for set payment_plan' do
      configuration.payment_plan = '2025'
      expect(configuration.covers_dpc?).to be_truthy
      expect(configuration.covers_dpc).to be_truthy
    end

    it 'returns false for no payment_plan set' do
      configuration.payment_plan = nil
      expect(configuration.covers_dpc?).to be_falsey
      expect(configuration.covers_dpc).to be_falsey
    end
  end
end

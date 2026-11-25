# == Schema Information
#
# Table name: configurations
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

  describe '#payment_commitment' do
    it 'should return the current year\'s payment commitment' do
      commitment = create(:payment_commitment, year: Date.current.year, sponsor: configuration.partner)
      expect(configuration.payment_commitment).to eq(commitment)
    end
  end

  describe '#covers_ldf?' do
    context 'with a commitment for this current year' do
      let!(:commitment) { create(:payment_commitment, year: Date.current.year, covers_ldf: true, sponsor: configuration.partner) }

      it 'should return the covers_ldf value from the commitment' do
        configuration.covers_ldf = false
        expect(configuration.covers_ldf?).to be true
        expect(configuration.covers_ldf).to be true
      end
    end

    context 'without a payment commitment' do
      it 'should return the covers_ldf value from the configuration' do
        configuration.covers_ldf = false
        expect(configuration.covers_ldf?).to be false
        expect(configuration.covers_ldf).to be false
      end
    end
  end

  describe '#ldf_limit' do
    context 'with a commitment for this current year' do
      let!(:commitment) { create(:payment_commitment, year: Date.current.year, ldf_size_limit: 100, sponsor: configuration.partner) }

      it 'should return the ldf_size_limit from the commitment' do
        configuration.ldf_limit = 200
        expect(configuration.ldf_limit).to eq(100)
      end
    end

    context 'without a payment commitment' do
      it 'should return the ldf_limit value from the configuration' do
        configuration.ldf_limit = 200
        expect(configuration.ldf_limit).to eq(200)
      end
    end
  end

  describe '#yearly_ldf_limit' do
    context 'with a commitment for this current year' do
      let!(:commitment) do
        create(:payment_commitment, year: Date.current.year, ldf_commitment: 200, ldf_carryover: 100, sponsor: configuration.partner)
      end

      it 'should return the sum of ldf_commitment and ldf_carryover from the commitment' do
        configuration.yearly_ldf_limit = 500
        expect(configuration.yearly_ldf_limit).to eq(300)
      end
    end

    context 'without a payment commitment' do
      it 'should return the yearly_ldf_limit value from the configuration' do
        configuration.yearly_ldf_limit = 500
        expect(configuration.yearly_ldf_limit).to eq(500)
      end
    end
  end
end

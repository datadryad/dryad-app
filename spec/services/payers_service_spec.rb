describe PayersService do
  let(:tenant) { create(:tenant) }
  let(:sponsored_tenant) { create(:tenant, id: 'sponsored', sponsor: tenant) }

  subject { PayersService.new(tenant) }

  describe '#initialize' do
    it 'sets proper attributes' do
      expect(subject.payer).to eq(tenant)
    end
  end

  describe '#is_2025_payer?' do
    subject { PayersService.new(tenant).is_2025_payer? }

    context 'when payer payment plan is 2025' do
      let!(:payment_configuration) { create(:payment_configuration, partner: tenant, payment_plan: '2025') }

      it { is_expected.to be_truthy }
    end

    (PaymentConfiguration.payment_plans.keys - ['2025']).each do |plan|
      context "when payer payment plan is #{plan}" do
        let!(:payment_configuration) { create(:payment_configuration, partner: tenant, payment_plan: plan) }

        it { is_expected.to be_falsey }
      end
    end

    context 'when is sponsored' do
      let!(:payment_configuration) { create(:payment_configuration, partner: tenant, payment_plan: '2025') }

      it 'returns true' do
        expect(PayersService.new(tenant).is_2025_payer?).to be_truthy
        expect(PayersService.new(sponsored_tenant).is_2025_payer?).to be_truthy
      end
    end
  end

  describe '#payment_sponsor' do
    subject { PayersService.new(tenant).payment_sponsor }

    context 'when is nil' do
      it 'returns true' do
        expect(PayersService.new(nil).payment_sponsor).to be_nil
      end
    end

    context 'when is not sponsored' do
      it 'returns self' do
        expect(PayersService.new(tenant).payment_sponsor).to eq(tenant)
      end
    end

    context 'when is sponsored' do
      it 'returns the sponsor' do
        expect(PayersService.new(sponsored_tenant).payment_sponsor).to eq(tenant)
      end
    end

    context 'when is payer does not have payment_sponsor defined' do
      let(:user) { create(:user) }

      it 'returns self' do
        expect(PayersService.new(user).payment_sponsor).to eq(user)
      end
    end
  end
end

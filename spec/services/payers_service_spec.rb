describe PayersService do
  let(:tenant) { create(:tenant) }

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
  end
end

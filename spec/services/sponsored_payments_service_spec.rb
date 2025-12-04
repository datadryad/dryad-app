RSpec.shared_examples('creates sponsored payment log') do
  it 'creates SponsoredPaymentLog record' do
    expect { subject.log_payment }.to change { SponsoredPaymentLog.count }.by(1)
  end
end

RSpec.shared_examples('does not create sponsored payment log') do
  it 'does not create any SponsoredPaymentLog record' do
    expect { subject.log_payment }.not_to(change { SponsoredPaymentLog.count })
  end
end

describe SponsoredPaymentsService do
  let(:identifier) { create(:identifier) }
  let(:total_file_size) { 10_000_000_001 }
  let!(:tenant) { create(:tenant) }
  let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, yearly_ldf_limit: 1_000) }
  let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: total_file_size) }

  let(:subject) { SponsoredPaymentsService.new(resource) }

  describe '#initialize' do
    it 'sets proper attributes' do
      expect(subject.resource).to eq(resource)
      expect(subject.payer).to eq(tenant)
    end
  end

  describe '#log_payment' do
    context 'when payer is not set' do
      let!(:payment_conf) { nil }

      include_examples('does not create sponsored payment log')
    end

    context 'when payer exists' do
      context 'and a payment record exists' do
        include_examples('creates sponsored payment log')
      end

      context 'and a invoice payment record exists' do
        let!(:payment) { create(:resource_payment, resource: resource, pay_with_invoice: true) }

        include_examples('does not create sponsored payment log')
      end

      context 'and a CC payment record exists' do
        context 'when payment succeeded' do
          let!(:payment) { create(:resource_payment, resource: resource, pay_with_invoice: false, status: :paid) }

          include_examples('does not create sponsored payment log')
        end

        context 'when payment failed' do
          let!(:payment) { create(:resource_payment, resource: resource, pay_with_invoice: false, status: :failed) }

          include_examples('does not create sponsored payment log')
        end

        context 'when payment is just created' do
          let!(:payment) { create(:resource_payment, resource: resource, pay_with_invoice: false, status: :created) }

          include_examples('creates sponsored payment log')
        end
      end
    end
  end
end

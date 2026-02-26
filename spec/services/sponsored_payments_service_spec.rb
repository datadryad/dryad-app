RSpec.shared_examples('creates sponsored payment log') do
  it 'creates SponsoredPaymentLog record' do
    expect { subject.log_payment }.to change { SponsoredPaymentLog.count }.by(1)
  end
end

RSpec.shared_examples('does not create sponsored payment log') do
  it 'does not create any SponsoredPaymentLog record' do
    # subject.log_payment
    # pp tenant.payment_logs.last
    expect { subject.log_payment }.not_to(change { SponsoredPaymentLog.count })
  end
end

describe SponsoredPaymentsService do
  let(:identifier) { create(:identifier) }
  let(:total_file_size) { 10_000_000_001 }
  let!(:tenant) { create(:tenant) }
  let!(:payment_conf) do
    create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true, yearly_ldf_limit: 1_000)
  end
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

    (PaymentConfiguration.payment_plans.keys - ['2025']).each do |plan|
      context "when payer payment plan is #{plan}" do
        let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: plan) }

        include_examples('does not create sponsored payment log')
      end
    end

    context 'when payer exists with a 2025 payment plan' do
      context 'when LDF amount limit is reached' do
        context 'and a payment record exists' do
          include_examples('creates sponsored payment log')

          it 'has correct info' do
            subject.log_payment

            expect(tenant.payment_logs.count).to eq(1)
            expect(tenant.payment_logs.last.attributes).to include(
              {
                resource_id: resource.id,
                payer_id: tenant.id,
                payer_type: tenant.class.name,
                ldf: 259,
                sponsor_id: tenant.id
              }.stringify_keys
            )
          end
        end

        context 'when tenant has a sponsor' do
          let!(:sponsor_tenant) { create(:tenant, id: 'sponsor') }
          let!(:tenant) { create(:tenant, id: 'payer', sponsor_id: sponsor_tenant.id) }
          let!(:payment_conf) do
            create(:payment_configuration, partner: sponsor_tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true, yearly_ldf_limit: 1_000)
          end

          include_examples('creates sponsored payment log')

          it 'has correct info' do
            subject.log_payment

            expect(tenant.payment_logs.count).to eq(1)
            expect(tenant.payment_logs.last.attributes).to include(
              {
                resource_id: resource.id,
                payer_id: tenant.id,
                payer_type: tenant.class.name,
                ldf: 259,
                sponsor_id: sponsor_tenant.id
              }.stringify_keys
            )
          end
        end
      end

      context 'when LDF size is not reached' do
        let!(:payment_conf) do
          create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true, ldf_limit: 5)
        end

        context 'and a payment record exists' do
          include_examples('creates sponsored payment log')

          it 'has correct info' do
            subject.log_payment

            expect(tenant.payment_logs.count).to eq(1)
            expect(tenant.payment_logs.last.attributes).to include(
              {
                resource_id: resource.id,
                payer_id: tenant.id,
                payer_type: tenant.class.name,
                ldf: 259,
                sponsor_id: tenant.id
              }.stringify_keys
            )
          end
        end

        context 'when tenant has a sponsor' do
          let!(:sponsor_tenant) { create(:tenant, id: 'sponsor') }
          let!(:tenant) { create(:tenant, id: 'payer', sponsor_id: sponsor_tenant.id) }
          let!(:payment_conf) do
            create(:payment_configuration, partner: sponsor_tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true, ldf_limit: 5)
          end

          include_examples('creates sponsored payment log')

          it 'has correct info' do
            subject.log_payment

            expect(tenant.payment_logs.count).to eq(1)
            expect(tenant.payment_logs.last.attributes).to include(
              {
                resource_id: resource.id,
                payer_id: tenant.id,
                payer_type: tenant.class.name,
                ldf: 259,
                sponsor_id: sponsor_tenant.id
              }.stringify_keys
            )
          end
        end
      end

      context 'when LDF size is reached' do
        let(:total_file_size) { 50_000_000_001 }
        let!(:payment_conf) do
          create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true, ldf_limit: 1)
        end

        context 'and a payment record exists' do
          include_examples('creates sponsored payment log')

          it 'has correct info' do
            subject.log_payment

            expect(tenant.payment_logs.count).to eq(1)
            expect(tenant.payment_logs.last.attributes).to include(
              {
                resource_id: resource.id,
                payer_id: tenant.id,
                payer_type: tenant.class.name,
                ldf: 259,
                sponsor_id: tenant.id
              }.stringify_keys
            )
          end
        end

        context 'when tenant has a sponsor' do
          let!(:sponsor_tenant) { create(:tenant, id: 'sponsor') }
          let!(:tenant) { create(:tenant, id: 'payer', sponsor_id: sponsor_tenant.id) }
          let!(:payment_conf) do
            create(:payment_configuration, partner: sponsor_tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true, ldf_limit: 2)
          end

          include_examples('creates sponsored payment log')

          it 'has correct info' do
            subject.log_payment

            expect(tenant.payment_logs.count).to eq(1)
            expect(tenant.payment_logs.last.attributes).to include(
              {
                resource_id: resource.id,
                payer_id: tenant.id,
                payer_type: tenant.class.name,
                ldf: 464,
                sponsor_id: sponsor_tenant.id
              }.stringify_keys
            )
          end
        end
      end

      context 'does not create a log if amount is 0' do
        context 'when ldf is in free tier' do
          let(:total_file_size) { 9_000_000_001 }

          include_examples('does not create sponsored payment log')
        end

        context 'when ldf is already paid on previous resource' do
          let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: total_file_size, created_at: 1.minute.ago) }

          it 'has correct info' do
            subject.log_payment

            expect(tenant.payment_logs.count).to eq(1)
            expect(tenant.payment_logs.last.attributes).to include(
              {
                resource_id: resource.id,
                payer_id: tenant.id,
                payer_type: tenant.class.name,
                ldf: 259,
                sponsor_id: tenant.id
              }.stringify_keys
            )

            new_resource = create(:resource, identifier: identifier, tenant: tenant, total_file_size: 11_000_000_000)
            expect { SponsoredPaymentsService.new(new_resource).log_payment }.not_to(change { SponsoredPaymentLog.count })
          end
        end
      end
    end
  end
end

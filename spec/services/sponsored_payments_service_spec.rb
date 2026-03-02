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
  let!(:payment_conf) do
    create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true, yearly_ldf_limit: 1_000)
  end
  let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: total_file_size) }
  # before { identifier.reload }

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

      context 'if files are deleted' do
        let!(:payment_conf) do
          create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true)
        end
        let(:identifier) { create(:identifier, last_invoiced_file_size: 110_000_000_000) }

        context 'when each tier has its own log' do
          let!(:res1) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: 70_000_000_000, created_at: 10.minute.ago) }
          let!(:ca1) { create(:curation_activity, status: :queued, resource: res1) }
          let!(:log1) { create(:sponsored_payment_log, resource: res1, ldf: 464, payer: tenant, sponsor_id: tenant.id) }
          let!(:res2) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: 110_000_000_000, created_at: 9.minute.ago) }
          let!(:ca2) { create(:curation_activity, status: :queued, resource: res2) }
          let!(:log2) { create(:sponsored_payment_log, resource: res2, ldf: 1_123, payer: tenant, sponsor_id: tenant.id) }

          context 'when ldf is in the same tier' do
            let(:total_file_size) { 105_000_000_000 }

            include_examples('does not create sponsored payment log')

            it 'updates last_invoiced_file_size' do
              subject.log_payment

              expect(identifier.reload.last_invoiced_file_size).to eq(105_000_000_000)
            end
          end

          context 'when ldf is one tier lower' do
            let(:total_file_size) { 60_000_000_000 }

            it 'deletes one log and does not create a new one' do
              expect(log2.reload.deleted?).to be_falsey
              expect(tenant.payment_logs.count).to eq(2)
              subject.log_payment

              expect(log2.reload.deleted?).to be_truthy
              expect(tenant.payment_logs.count).to eq(1)
            end

            it 'updates last_invoiced_file_size' do
              subject.log_payment

              expect(identifier.reload.last_invoiced_file_size).to eq(60_000_000_000)
            end
          end

          context 'when ldf is 2 tier lower each having there own logs' do
            let(:total_file_size) { 15_000_000_000 }

            it 'deletes both logs and creates a new one' do
              expect(log1.reload.deleted?).to be_falsey
              expect(log2.reload.deleted?).to be_falsey
              expect(tenant.payment_logs.count).to eq(2)
              subject.log_payment

              expect(log1.reload.deleted?).to be_truthy
              expect(log2.reload.deleted?).to be_truthy
              expect(tenant.payment_logs.count).to eq(1)
            end

            context 'when something fails' do
              it 'does not delete anything' do
                allow(SponsoredPaymentLog).to receive(:create).and_raise(ActiveRecord::RecordInvalid)

                expect(tenant.payment_logs.count).to eq(2)
                expect { subject.log_payment }.to raise_error(ActiveRecord::RecordInvalid)
                expect(tenant.payment_logs.count).to eq(2)
              end
            end

            it 'updates last_invoiced_file_size' do
              subject.log_payment

              expect(identifier.reload.last_invoiced_file_size).to eq(15_000_000_000)
            end

            context 'when there is an intermediary published version' do
              let!(:ca) { create(:curation_activity, status: :published, resource: res1) }

              it 'deletes newer logs and stops at the published one and does not create any new log' do
                expect(log2.reload.deleted?).to be_falsey
                expect(tenant.payment_logs.count).to eq(2)
                subject.log_payment

                expect(log1.reload.deleted?).to be_falsey
                expect(log2.reload.deleted?).to be_truthy
                expect(tenant.payment_logs.count).to eq(1)
              end
            end
          end

          context 'when goes back to free tier' do
            let(:total_file_size) { 5_000_000_000 }

            it 'deletes both logs log' do
              expect(tenant.payment_logs.count).to eq(2)
              subject.log_payment

              expect(tenant.payment_logs.count).to eq(0)
            end

            it 'updates last_invoiced_file_size' do
              subject.log_payment

              expect(identifier.reload.last_invoiced_file_size).to eq(5_000_000_000)
            end
          end
        end

        context 'when there is only one log' do
          let!(:res1) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: 20_000_000_000, created_at: 10.minute.ago) }
          let!(:ca1) { create(:curation_activity, status: :queued, resource: res1) }
          let!(:log1) { create(:sponsored_payment_log, resource: res1, ldf: 259, payer: tenant, sponsor_id: tenant.id) }
          let!(:res2) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: 110_000_000_000, created_at: 9.minute.ago) }
          let!(:ca2) { create(:curation_activity, status: :queued, resource: res2) }
          let!(:log2) { create(:sponsored_payment_log, resource: res2, ldf: 1_123, payer: tenant, sponsor_id: tenant.id) }

          context 'when ldf is in the same tier' do
            let(:total_file_size) { 105_000_000_000 }

            include_examples('does not create sponsored payment log')

            it 'updates last_invoiced_file_size' do
              subject.log_payment

              expect(identifier.reload.last_invoiced_file_size).to eq(105_000_000_000)
            end
          end

          context 'when ldf is one tier lower' do
            let(:total_file_size) { 70_000_000_000 }

            it 'deletes one log and creates a new one' do
              expect(log2.reload.deleted?).to be_falsey
              expect(tenant.payment_logs.count).to eq(2)
              subject.log_payment

              expect(log1.reload.deleted?).to be_falsey
              expect(log2.reload.deleted?).to be_truthy
              # creates a new log
              expect(tenant.payment_logs.count).to eq(2)
              expect(tenant.payment_logs.last.attributes).to include(
                {
                  resource_id: resource.id,
                  payer_id: tenant.id,
                  payer_type: tenant.class.name,
                  ldf: 464 - 259,
                  sponsor_id: tenant.id
                }.stringify_keys
              )
            end

            it 'updates last_invoiced_file_size' do
              subject.log_payment

              expect(identifier.reload.last_invoiced_file_size).to eq(70_000_000_000)
            end
          end

          context 'when ldf is 2 tier lower and there is already a log on this tier' do
            let(:total_file_size) { 15_000_000_000 }

            it 'deletes larger tier log' do
              expect(log2.reload.deleted?).to be_falsey
              expect(tenant.payment_logs.count).to eq(2)
              subject.log_payment

              expect(log1.reload.deleted?).to be_falsey
              expect(log2.reload.deleted?).to be_truthy
              expect(tenant.payment_logs.count).to eq(1)
            end

            it 'updates last_invoiced_file_size' do
              subject.log_payment

              expect(identifier.reload.last_invoiced_file_size).to eq(15_000_000_000)
            end
          end

          context 'when goes back to free tier' do
            let(:total_file_size) { 5_000_000_000 }

            it 'deletes both logs log' do
              expect(tenant.payment_logs.count).to eq(2)
              subject.log_payment

              expect(tenant.payment_logs.count).to eq(0)
            end

            it 'updates last_invoiced_file_size' do
              subject.log_payment

              expect(identifier.reload.last_invoiced_file_size).to eq(5_000_000_000)
            end
          end
        end
      end
    end
  end
end

describe PaymentLimitsService do
  describe 'when tenant is the payer' do
    let(:identifier) { create(:identifier) }
    let(:total_file_size) { 10_000_000_001 }
    let!(:sponsor_tenant) { create(:tenant, id: 'sponsor') }
    let!(:tenant) { create(:tenant, sponsor: sponsor_tenant, id: 'payer') }
    let!(:other_tenant) { create(:tenant, sponsor: sponsor_tenant, id: 'other') }
    let!(:payment_conf) do
      create(:payment_configuration,
             partner: tenant,
             payment_plan: '2025',
             covers_dpc: true,
             covers_ldf: true,
             ldf_limit: 1,
             yearly_ldf_limit: 1_000)
    end
    let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: total_file_size) }
    let(:payer) { tenant }

    let(:subject) { PaymentLimitsService.new(resource, payer) }

    describe '#initialize' do
      it 'sets proper attributes' do
        expect(subject.resource).to eq(resource)
        expect(subject.payer).to eq(payer)
      end
    end

    describe '#limits_exceeded?' do
      let(:subject) { PaymentLimitsService.new(resource, payer).limits_exceeded? }

      context 'when payer has a 2025 payment plan' do
        context 'when payer amount limit is set' do
          context 'but not reached' do
            it { is_expected.to be_falsey }
          end

          context 'when limit is already exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: tenant, ldf: 1_001) }

            it { is_expected.to be_truthy }

            context 'but resource LDF is 0' do
              let(:total_file_size) { 10_000 }

              it { is_expected.to be_falsey }
            end
          end

          context 'when limit is not reached but with current resource it will be exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: tenant, ldf: 999) }

            it { is_expected.to be_truthy }
          end

          context 'when limit is not reached and with current resource it will not be exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: tenant, ldf: 100) }

            it { is_expected.to be_falsey }
          end

          context 'but resource LDF is 0' do
            let(:total_file_size) { 10_000 }

            it { is_expected.to be_falsey }
          end

          context 'with logs on previous year' do
            let!(:log) { create(:sponsored_payment_log, payer: tenant, ldf: 1_001, created_at: 1.year.ago) }

            it { is_expected.to be_falsey }
          end
        end

        context 'when sponsor amount limit is set' do
          let!(:payment_conf2) do
            create(:payment_configuration,
                   partner: sponsor_tenant,
                   payment_plan: '2025',
                   covers_dpc: true,
                   covers_ldf: true,
                   yearly_ldf_limit: 1_000)
          end

          context 'but not reached' do
            it { is_expected.to be_falsey }
          end

          context 'when limit is already exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: other_tenant, ldf: 1_001, sponsor_id: sponsor_tenant.id) }

            it { is_expected.to be_truthy }

            context 'but resource LDF is 0' do
              let(:total_file_size) { 10_000 }

              it { is_expected.to be_falsey }
            end
          end

          context 'when limit is not reached but with current resource it will be exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: other_tenant, ldf: 999, sponsor_id: sponsor_tenant.id) }

            it { is_expected.to be_truthy }
          end

          context 'when limit is not reached and with current resource it will not be exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: other_tenant, ldf: 100, sponsor_id: sponsor_tenant.id) }

            it { is_expected.to be_falsey }
          end

          context 'but resource LDF is 0' do
            let(:total_file_size) { 10_000 }

            it { is_expected.to be_falsey }
          end

          context 'with logs on previous year' do
            let!(:log) { create(:sponsored_payment_log, payer: tenant, ldf: 1_001, created_at: 1.year.ago, sponsor_id: sponsor_tenant.id) }
            let!(:log2) { create(:sponsored_payment_log, payer: other_tenant, ldf: 1_001, created_at: 1.year.ago, sponsor_id: sponsor_tenant.id) }

            it { is_expected.to be_falsey }
          end
        end

        context 'when dataset size limit is set' do
          context 'but not reached' do
            it { is_expected.to be_falsey }
          end

          context 'when limit is not reached but with current version it will be exceeded' do
            let(:total_file_size) { 50_000_000_001 }

            it { is_expected.to be_truthy }
          end

          context 'when limit is not reached and with current resource it will not be exceeded' do
            let(:total_file_size) { 50_000_000_000 }

            it { is_expected.to be_falsey }
          end
        end

        context 'when no limit is set' do
          let!(:payment_conf) do
            create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, yearly_ldf_limit: nil)
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when payer is not set' do
        let(:payer) { nil }
        it { is_expected.to be_truthy }
      end

      context 'when payer has different payment plan than 2025' do
        let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: 'TIERED', covers_dpc: true) }

        it { is_expected.to be_falsey }
      end
    end

    describe '#payment_allowed?' do
      it 'returns true if limit is exceeded' do
        expect(subject).to receive(:limits_exceeded?).and_return(true)
        expect(subject.payment_allowed?).to be_falsey
      end

      it 'returns false if limit is not exceeded' do
        expect(subject).to receive(:limits_exceeded?).and_return(false)
        expect(subject.payment_allowed?).to be_truthy
      end
    end
  end

  describe 'when journal is the payer' do
    let(:identifier) { create(:identifier) }
    let(:total_file_size) { 10_000_000_001 }
    let!(:tenant) { create(:tenant, sponsor: sponsor_tenant, id: 'payer') }
    let!(:sponsor_journal_org) { create(:journal_organization) }
    let!(:journal) { create(:journal, sponsor: sponsor_journal_org) }
    let!(:other_journal) { create(:journal, sponsor: sponsor_journal_org) }
    let!(:payment_conf) do
      create(:payment_configuration,
             partner: journal,
             payment_plan: '2025',
             covers_dpc: true,
             covers_ldf: true,
             ldf_limit: 1,
             yearly_ldf_limit: 1_000)
    end
    let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: total_file_size) }
    let(:payer) { journal }

    let(:subject) { PaymentLimitsService.new(resource, payer) }

    describe '#initialize' do
      it 'sets proper attributes' do
        expect(subject.resource).to eq(resource)
        expect(subject.payer).to eq(payer)
      end
    end

    describe '#limits_exceeded?' do
      let(:subject) { PaymentLimitsService.new(resource, payer).limits_exceeded? }

      context 'when payer has a 2025 payment plan' do
        context 'when payer amount limit is set' do
          context 'but not reached' do
            it { is_expected.to be_falsey }
          end

          context 'when limit is already exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: journal, ldf: 1_001) }

            it { is_expected.to be_truthy }

            context 'but resource LDF is 0' do
              let(:total_file_size) { 10_000 }

              it { is_expected.to be_falsey }
            end
          end

          context 'when limit is not reached but with current resource it will be exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: journal, ldf: 999) }

            it { is_expected.to be_truthy }
          end

          context 'when limit is not reached and with current resource it will not be exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: journal, ldf: 100) }

            it { is_expected.to be_falsey }
          end

          context 'but resource LDF is 0' do
            let(:total_file_size) { 10_000 }

            it { is_expected.to be_falsey }
          end

          context 'with logs on previous year' do
            let!(:log) { create(:sponsored_payment_log, payer: journal, ldf: 1_001, created_at: 1.year.ago) }

            it { is_expected.to be_falsey }
          end
        end

        context 'when sponsor amount limit is set' do
          let!(:payment_conf2) do
            create(:payment_configuration,
                   partner: sponsor_journal_org,
                   payment_plan: '2025',
                   covers_dpc: true,
                   covers_ldf: true,
                   yearly_ldf_limit: 1_000)
          end

          context 'but not reached' do
            it { is_expected.to be_falsey }
          end

          context 'when limit is already exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: other_journal, ldf: 1_001, sponsor_id: sponsor_journal_org.id) }

            it { is_expected.to be_truthy }

            context 'but resource LDF is 0' do
              let(:total_file_size) { 10_000 }

              it { is_expected.to be_falsey }
            end
          end

          context 'when limit is not reached but with current resource it will be exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: other_journal, ldf: 999, sponsor_id: sponsor_journal_org.id) }

            it { is_expected.to be_truthy }
          end

          context 'when limit is not reached and with current resource it will not be exceeded' do
            let!(:log) { create(:sponsored_payment_log, payer: other_journal, ldf: 100, sponsor_id: sponsor_journal_org.id) }

            it { is_expected.to be_falsey }
          end

          context 'but resource LDF is 0' do
            let(:total_file_size) { 10_000 }

            it { is_expected.to be_falsey }
          end

          context 'with logs on previous year' do
            let!(:log) { create(:sponsored_payment_log, payer: journal, ldf: 1_001, created_at: 1.year.ago, sponsor_id: sponsor_journal_org.id) }
            let!(:log2) do
              create(:sponsored_payment_log, payer: other_journal, ldf: 1_001, created_at: 1.year.ago, sponsor_id: sponsor_journal_org.id)
            end

            it { is_expected.to be_falsey }
          end
        end

        context 'when dataset size limit is set' do
          context 'but not reached' do
            it { is_expected.to be_falsey }
          end

          context 'when limit is not reached but with current version it will be exceeded' do
            let(:total_file_size) { 50_000_000_001 }

            it { is_expected.to be_truthy }
          end

          context 'when limit is not reached and with current resource it will not be exceeded' do
            let(:total_file_size) { 50_000_000_000 }

            it { is_expected.to be_falsey }
          end
        end

        context 'when no limit is set' do
          let!(:payment_conf) do
            create(:payment_configuration, partner: journal, payment_plan: '2025', covers_dpc: true, yearly_ldf_limit: nil)
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when payer is not set' do
        let(:payer) { nil }
        it { is_expected.to be_truthy }
      end

      context 'when payer has different payment plan than 2025' do
        let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: 'TIERED', covers_dpc: true) }

        it { is_expected.to be_falsey }
      end
    end

    describe '#payment_allowed?' do
      it 'returns true if limit is exceeded' do
        expect(subject).to receive(:limits_exceeded?).and_return(true)
        expect(subject.payment_allowed?).to be_falsey
      end

      it 'returns false if limit is not exceeded' do
        expect(subject).to receive(:limits_exceeded?).and_return(false)
        expect(subject.payment_allowed?).to be_truthy
      end
    end
  end
end

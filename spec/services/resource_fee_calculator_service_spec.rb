describe ResourceFeeCalculatorService do
  let(:options) { { generate_invoice: false } }
  let(:identifier) { create(:identifier) }

  context 'with institution type' do
    let!(:tenant) { create(:tenant) }
    let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true) }
    let(:resource) { create(:resource, identifier: identifier, tenant: tenant) }

    it_should_behave_like 'calling FeeCalculatorService', 'institution'
  end

  context 'with publisher type' do
    let!(:journal) { create(:journal) }
    let!(:payment_conf) { create(:payment_configuration, partner: journal, payment_plan: '2025') }
    let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first]) }

    it_should_behave_like 'calling FeeCalculatorService', 'publisher'
  end

  context 'with publisher type based on funder' do
    let(:resource) { create(:resource, identifier: identifier) }
    let(:contributor) do
      create(:contributor, contributor_name: 'National Cancer Institute',
                           contributor_type: 'funder', resource_id: resource.id)
    end
    let!(:funder) { create(:funder, name: contributor.contributor_name, enabled: true) }
    let!(:payment_conf) { create(:payment_configuration, partner: funder, payment_plan: '2025', covers_dpc: true) }

    it_should_behave_like 'calling FeeCalculatorService', 'publisher'
  end

  context 'with individual type' do
    let(:resource) { create(:resource, identifier: identifier) }

    it_should_behave_like 'calling FeeCalculatorService', 'publisher'
  end

  context 'with waiver type' do
    let(:identifier) { create(:identifier, payment_type: 'waiver') }
    let(:resource) { create(:resource, identifier: identifier) }

    it_should_behave_like 'calling FeeCalculatorService', 'waiver'
  end

  context 'with non 2025 fee model but is still paying old fees' do
    let(:journal_organization) { create(:journal_organization, name: 'The Royal Society') }
    let!(:journal) { create(:journal, sponsor: journal_organization) }
    let!(:payment_conf) { create(:payment_configuration, partner: journal, payment_plan: 'TIERED', covers_dpc: true) }
    let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first]) }

    it 'returns an error only for exceptions' do

      response = ResourceFeeCalculatorService.new(resource).calculate({})
      expect(response).to eq({
                               error: true,
                               message: OLD_PAYMENT_SYSTEM_MESSAGE,
                               old_payment_system: true
                             })
    end
  end

  context 'with non 2025 payment plan, but is not paying old fees' do
    context 'on new submission' do
      let(:journal_organization) { create(:journal_organization, name: 'NOT The Royal Society') }
      let!(:journal) { create(:journal, sponsor: journal_organization) }
      let!(:payment_conf) { create(:payment_configuration, partner: journal, payment_plan: 'TIERED', covers_dpc: true) }
      let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first]) }

      it_should_behave_like 'calling FeeCalculatorService', 'individual'
      it 'user pays individual DPC fee' do
        expect(ResourceFeeCalculatorService.new(resource).calculate({})[:total]).to eq(150)
      end
    end

    context 'on second version' do
      let(:identifier) { create(:identifier, payment_type: 'journal_TIERED') }
      let(:journal_organization) { create(:journal_organization, name: 'NOT The Royal Society') }
      let!(:journal) { create(:journal, sponsor: journal_organization) }
      let!(:payment_conf) { create(:payment_configuration, partner: journal, payment_plan: 'TIERED', covers_dpc: true) }
      let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first]) }

      it_should_behave_like 'calling FeeCalculatorService', 'publisher'

      context 'when storage tier is not changed' do
        it 'user does not pay anything' do
          expect(ResourceFeeCalculatorService.new(resource).calculate({})[:total]).to eq(0)
        end
      end

      context 'when storage tier is not changed' do
        let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first], total_file_size: 70_000_000_000) }

        it 'user pays LDF fee at publisher pricing tier' do
          expect(ResourceFeeCalculatorService.new(resource).calculate({})[:total]).to eq(464)
        end
      end
    end
  end
end

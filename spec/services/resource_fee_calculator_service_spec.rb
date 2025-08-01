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

  context 'with non 2025 fee model' do
    let(:resource) { create(:resource, identifier: identifier) }
    let(:contributor) do
      create(:contributor, contributor_name: 'National Cancer Institute',
                           contributor_type: 'funder', resource_id: resource.id)
    end
    let!(:funder) { create(:funder, name: contributor.contributor_name, enabled: true) }
    let!(:payment_conf) { create(:payment_configuration, partner: funder, payment_plan: 'tiered', covers_dpc: true) }

    it 'returns an error' do
      response = ResourceFeeCalculatorService.new(resource).calculate({})
      expect(response).to eq({
                               error: true,
                               message: OLD_PAYMENT_SYSTEM_MESSAGE,
                               old_payment_system: true
                             })
    end
  end
end

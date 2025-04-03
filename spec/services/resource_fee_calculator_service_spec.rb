describe ResourceFeeCalculatorService do
  let(:options) { { generate_invoice: false } }
  let(:identifier) { create(:identifier) }

  context 'with institution type' do
    let!(:tenant) { create(:tenant, payment_plan: '2025', covers_dpc: true) }
    let(:resource) { create(:resource, identifier: identifier, tenant: tenant) }

    it_should_behave_like 'calling FeeCalculatorService', 'institution'
  end

  context 'with publisher type' do
    let!(:journal) { create(:journal, payment_plan_type: '2025') }
    let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first]) }

    it_should_behave_like 'calling FeeCalculatorService', 'publisher'
  end

  context 'with publisher type based on funder' do
    let(:resource) { create(:resource, identifier: identifier) }
    let(:contributor) do
      create(:contributor, contributor_name: 'National Cancer Institute',
                           contributor_type: 'funder', resource_id: resource.id)
    end
    let!(:funder) { create(:funder, name: contributor.contributor_name, payment_plan: '2025', covers_dpc: true, enabled: true) }

    it_should_behave_like 'calling FeeCalculatorService', 'publisher'
  end

  context 'with individual type' do
    let(:resource) { create(:resource, identifier: identifier) }

    it_should_behave_like 'calling FeeCalculatorService', 'publisher'
  end
end

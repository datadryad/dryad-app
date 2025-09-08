RSpec.describe 'FeeCalculatorController', type: :request do
  let(:service_instance) { double(:FeeCalculatorService) }
  let(:identifier) { create(:identifier) }

  describe '#fee_calculator_url' do
    before do
      allow(FeeCalculatorService).to receive(:new).with(type).and_return(service_instance)
      allow(service_instance).to receive(:calculate).with(options).and_return({ some_fee: 12 })

      get fee_calculator_url, params: { type: type }.merge(options)
    end

    describe '#institutional fee' do
      let(:type) { 'institution' }
      let(:options) { {} }

      context 'without any configuration' do
        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options)
        end
      end

      context 'with all configuration attrs' do
        let(:options) do
          {
            'low_middle_income_country' => true,
            'cover_storage_fee' => false,
            'dpc_tier' => '1',
            'service_tier' => '3',
            'storage_usage' => {
              '1' => '10',
              '4' => '43'
            }
          }
        end

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options)
        end
      end
    end

    describe '#publisher fee' do
      let(:type) { 'publisher' }
      let(:options) { { 'cover_storage_fee' => nil } }

      context 'without any configuration' do
        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options)
        end
      end

      context 'with all configuration attrs' do
        let(:options) do
          {
            'cover_storage_fee' => nil,
            'dpc_tier' => '1',
            'service_tier' => '3',
            'storage_usage' => {
              '1' => '10',
              '4' => '43'
            }
          }
        end

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options)
        end
      end
    end

    describe '#individual fee' do
      let(:type) { 'individual' }
      let(:options) { { 'generate_invoice' => nil } }

      context 'without any configuration' do
        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options)
        end
      end

      context 'with all configuration attrs' do
        let(:options) do
          {
            'generate_invoice' => true,
            'storage_size' => '10000'
          }
        end

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options)
        end
      end
    end
  end

  describe '#resource_fee_calculator_url(resource)' do
    before do
      allow(FeeCalculatorService).to receive(:new).with(type).and_return(service_instance)
      allow(service_instance).to receive(:calculate).with(options, resource: resource).and_return({ some_fee: 12 })
    end

    describe '#institutional fee' do
      let(:options) { {} }
      let(:type) { 'institution' }
      let!(:tenant) { create(:tenant) }
      let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true) }
      let(:identifier) { create(:identifier) }
      let(:resource) { create(:resource, identifier: identifier, tenant: tenant) }

      before do
        get resource_fee_calculator_url(resource), params: options
      end

      context 'without any configuration' do
        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with('institution')
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, resource: resource)
        end
      end

      context 'with all configuration attrs' do
        let(:options) { { 'generate_invoice' => true } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with('institution')
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, resource: resource)
        end
      end
    end

    describe '#publisher fee from journal' do
      let(:options) { {} }
      let(:type) { 'publisher' }
      let!(:journal) { create(:journal) }
      let!(:payment_conf) { create(:payment_configuration, partner: journal, payment_plan: '2025') }
      let(:identifier) { create(:identifier) }
      let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first]) }

      before do
        get resource_fee_calculator_url(resource), params: options
      end

      context 'without any configuration' do
        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with('publisher')
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, resource: resource)
        end
      end

      context 'with all configuration attrs' do
        let(:options) { { 'generate_invoice' => true } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with('publisher')
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, resource: resource)
        end
      end
    end

    describe '#publisher fee from funder' do
      let(:type) { 'publisher' }
      let(:resource) { create(:resource, identifier: identifier) }
      let(:contributor) do
        create(:contributor, contributor_name: 'National Cancer Institute',
                             contributor_type: 'funder', resource_id: resource.id)
      end
      let!(:funder) { create(:funder, name: contributor.contributor_name, enabled: true) }
      let!(:payment_conf) { create(:payment_configuration, partner: funder, payment_plan: '2025', covers_dpc: true) }

      before do
        get resource_fee_calculator_url(resource), params: options
      end

      context 'without any configuration' do
        let(:options) { {} }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with('publisher')
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, resource: resource)
        end
      end

      context 'with all configuration attrs' do
        let(:options) { { 'generate_invoice' => true } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with('publisher')
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, resource: resource)
        end
      end
    end

    describe '#individual fee' do
      let(:type) { 'individual' }
      let(:options) { {} }
      let(:identifier) { create(:identifier) }
      let(:resource) { create(:resource, identifier: identifier) }

      before do
        get resource_fee_calculator_url(resource), params: options
      end

      context 'without any configuration' do
        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with('individual')
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, resource: resource)
        end
      end

      context 'with all configuration attrs' do
        let(:options) { { 'generate_invoice' => true } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with('individual')
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, resource: resource)
        end
      end
    end

    describe '#waiver fee' do
      let(:type) { 'waiver' }
      let(:options) { {} }
      let(:identifier) { create(:identifier, payment_type: 'waiver') }
      let(:resource) { create(:resource, identifier: identifier) }

      before do
        get resource_fee_calculator_url(resource), params: options
      end

      it 'does not fail' do
        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'some_fee' => 12 })
      end

      it 'calls new with the correct type' do
        expect(FeeCalculatorService).to have_received(:new).with('waiver')
      end

      it 'calls calculate on the service instance with the correct params' do
        expect(service_instance).to have_received(:calculate).with(options, resource: resource)
      end
    end
  end

  describe 'examples in documentation table' do
    context 'sample institutional fee calculation' do
      let(:type) { 'institution' }

      it 'returns proper value on example 1' do
        get fee_calculator_path, params: { type: type, service_tier: '1', dpc_tier: '1' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 5_000, 'dpc_fee' => 0, 'total' => 5_000, 'storage_fee_label' => 'Large data fee' })
      end

      it 'returns proper value on example 2' do
        get fee_calculator_url, params: { type: type, service_tier: '4', dpc_tier: '10' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 30_000, 'dpc_fee' => 30_250, 'total' => 60_250, 'storage_fee_label' => 'Large data fee' })
      end

      it 'returns proper value on example 3' do
        get fee_calculator_url, params: { type: type, service_tier: '6', dpc_tier: '16' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 50_000, 'dpc_fee' => 58_250, 'total' => 108_250, 'storage_fee_label' => 'Large data fee' })
      end
    end

    context 'sample institutional fee calculation' do
      let(:type) { 'publisher' }

      it 'returns proper value on example 1' do
        get fee_calculator_path, params: { type: type, service_tier: '1', dpc_tier: '1' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 1_000, 'dpc_fee' => 0, 'total' => 1_000, 'storage_fee_label' => 'Large data fee' })
      end

      it 'returns proper value on example 2' do
        get fee_calculator_url, params: { type: type, service_tier: '6', dpc_tier: '10' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 12_500, 'dpc_fee' => 30_250, 'total' => 42_750, 'storage_fee_label' => 'Large data fee' })
      end

      it 'returns proper value on example 3' do
        get fee_calculator_url, params: { type: type, service_tier: '10', dpc_tier: '16' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 40_000, 'dpc_fee' => 58_250, 'total' => 98_250, 'storage_fee_label' => 'Large data fee' })
      end
    end
  end

  def json_response
    JSON.parse(response.body)['fees']
  end
end

RSpec.describe 'FeeCalculatorController', type: :request do

  describe '#institutional fee' do
    let(:type) { 'institution' }
    let(:service_instance) { double(:FeeCalculatorService) }
    let(:options) { { 'low_middle_income_country' => nil, 'cover_storage_fee' => nil } }

    describe '#fee_calculator_url' do
      let(:url) { fee_calculator_url }

      before do
        allow(FeeCalculatorService).to receive(:new).with(type).and_return(service_instance)
        allow(service_instance).to receive(:calculate).with(options, for_dataset: false).and_return({ some_fee: 12 })
      end

      context 'without any configuration' do
        before { get url, params: { type: type } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: false)
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

        before { get url, params: { type: type }.merge(options) }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: false)
        end
      end
    end

    describe '#dataset_fee_calculator_url' do
      let(:url) { dataset_fee_calculator_url }

      before do
        allow(FeeCalculatorService).to receive(:new).with(type).and_return(service_instance)
        allow(service_instance).to receive(:calculate).with(options, for_dataset: true).and_return({ some_fee: 12 })
      end

      context 'without any configuration' do
        before { get url, params: { type: type } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: true)
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

        before { get url, params: { type: type }.merge(options) }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: true)
        end
      end
    end
  end

  describe '#publisher fee' do
    let(:type) { 'publisher' }
    let(:service_instance) { double(:FeeCalculatorService) }
    let(:options) { { 'cover_storage_fee' => nil } }

    describe '#fee_calculator_url' do
      let(:url) { fee_calculator_url }

      before do
        allow(FeeCalculatorService).to receive(:new).with(type).and_return(service_instance)
        allow(service_instance).to receive(:calculate).with(options, for_dataset: false).and_return({ some_fee: 12 })
      end

      context 'without any configuration' do
        before { get url, params: { type: type } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: false)
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

        before { get url, params: { type: type }.merge(options) }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: false)
        end
      end
    end

    describe '#dataset_fee_calculator_url' do
      let(:url) { dataset_fee_calculator_url }

      before do
        allow(FeeCalculatorService).to receive(:new).with(type).and_return(service_instance)
        allow(service_instance).to receive(:calculate).with(options, for_dataset: true).and_return({ some_fee: 12 })
      end

      context 'without any configuration' do
        before { get url, params: { type: type } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: true)
        end
      end

      context 'with all configuration attrs' do
        let(:options) do
          {
            'cover_storage_fee' => true,
            'dpc_tier' => '1',
            'service_tier' => '3',
            'storage_usage' => {
              '1' => '10',
              '4' => '43'
            }
          }
        end

        before { get url, params: { type: type }.merge(options) }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: true)
        end
      end
    end
  end

  describe '#individual fee' do
    let(:type) { 'individual' }
    let(:service_instance) { double(:FeeCalculatorService) }
    let(:options) { { 'generate_invoice' => nil } }

    describe '#fee_calculator_url' do
      let(:url) { fee_calculator_url }

      before do
        allow(FeeCalculatorService).to receive(:new).with(type).and_return(service_instance)
        allow(service_instance).to receive(:calculate).with(options, for_dataset: false).and_return({ some_fee: 12 })
      end

      context 'without any configuration' do
        before { get url, params: { type: type } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: false)
        end
      end

      context 'with all configuration attrs' do
        let(:options) do
          {
            'generate_invoice' => true,
            'storage_size' => '10000'
          }
        end

        before { get url, params: { type: type }.merge(options) }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: false)
        end
      end
    end

    describe '#dataset_fee_calculator_url' do
      let(:url) { dataset_fee_calculator_url }

      before do
        allow(FeeCalculatorService).to receive(:new).with(type).and_return(service_instance)
        allow(service_instance).to receive(:calculate).with(options, for_dataset: true).and_return({ some_fee: 12 })
      end

      context 'without any configuration' do
        before { get url, params: { type: type } }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: true)
        end
      end

      context 'with all configuration attrs' do
        let(:options) do
          {
            'generate_invoice' => true,
            'storage_size' => '10000'
          }
        end

        before { get url, params: { type: type }.merge(options) }

        it 'does not fail' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'some_fee' => 12 })
        end

        it 'calls new with the correct type' do
          expect(FeeCalculatorService).to have_received(:new).with(type)
        end

        it 'calls calculate on the service instance with the correct params' do
          expect(service_instance).to have_received(:calculate).with(options, for_dataset: true)
        end
      end
    end
  end

  describe 'examples in documentation table' do
    context 'sample institutional fee calculation' do
      let(:type) { 'institution' }

      it 'returns proper value on example 1' do
        get fee_calculator_path, params: { type: type, service_tier: '1', dpc_tier: '1' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 5_000, 'dpc_fee' => 0, 'total' => 5_000 })
      end

      it 'returns proper value on example 2' do
        get fee_calculator_url, params: { type: type, service_tier: '4', dpc_tier: '10' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 30_000, 'dpc_fee' => 30_250, 'total' => 60_250 })
      end

      it 'returns proper value on example 3' do
        get fee_calculator_url, params: { type: type, service_tier: '6', dpc_tier: '16' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 50_000, 'dpc_fee' => 58_250, 'total' => 108_250 })
      end
    end

    context 'sample institutional fee calculation' do
      let(:type) { 'publisher' }

      it 'returns proper value on example 1' do
        get fee_calculator_path, params: { type: type, service_tier: '1', dpc_tier: '1' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 1_000, 'dpc_fee' => 0, 'total' => 1_000 })
      end

      it 'returns proper value on example 2' do
        get fee_calculator_url, params: { type: type, service_tier: '6', dpc_tier: '10' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 12_500, 'dpc_fee' => 30_250, 'total' => 42_750 })
      end

      it 'returns proper value on example 3' do
        get fee_calculator_url, params: { type: type, service_tier: '10', dpc_tier: '16' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ 'service_fee' => 40_000, 'dpc_fee' => 58_250, 'total' => 98_250 })
      end
    end
  end

  def json_response
    JSON.parse(response.body)['fees']
  end
end

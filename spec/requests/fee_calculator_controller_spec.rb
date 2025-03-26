RSpec.describe 'FeeCalculatorController', type: :request do

  describe '#institutional fee' do
    let(:type) { 'institution' }
    let(:service_instance) { double(:FeeCalculatorService) }
    let(:options) { { 'low_middle_income_country' => nil } }

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

  def json_response
    JSON.parse(response.body)['fees']
  end
end

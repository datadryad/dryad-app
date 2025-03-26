module FeeCalculator
  describe IndividualService do

    describe '#fee_calculator' do
      let(:options) { {} }
      let(:for_dataset) { false }
      subject { described_class.new(options, for_dataset: for_dataset).call }

      context 'without invoice fee' do
        context 'without any configuration' do
          it { is_expected.to eq({ storage_fee: 150, total: 150 }) }
        end

        context 'with storage_size at max limit' do
          let(:options) { { storage_size: 100_000_000_000 } }

          it { is_expected.to eq({ storage_fee: 808, total: 808 }) }
        end

        context 'with storage_size as min limit' do
          let(:options) { { storage_size: 100_000_000_001 } }

          it { is_expected.to eq({ storage_fee: 1_750, total: 1_750 }) }
        end

        # TODO: do we raise an error in this case? or add 0
        context 'with storage_size over 2TB limit' do
          let(:options) { { storage_size: 10_000_000_000_000 } }

          it { is_expected.to eq({ storage_fee: 0, total: 0 }) }
        end
      end

      context 'with invoice fee' do
        context 'without any configuration' do
          let(:options) { { generate_invoice: true } }

          it { is_expected.to eq({ storage_fee: 150, invoice_fee: 199, total: 349 }) }
        end

        context 'with storage_size at max limit' do
          let(:options) { { generate_invoice: true, storage_size: 100_000_000_000 } }

          it { is_expected.to eq({ storage_fee: 808, invoice_fee: 199, total: 1007 }) }
        end

        context 'with storage_size as min limit' do
          let(:options) { { generate_invoice: true, storage_size: 100_000_000_001 } }

          it { is_expected.to eq({ storage_fee: 1_750, invoice_fee: 199, total: 1949 }) }
        end

        # TODO: do we raise an error in this case? or add 0
        context 'with storage_size over 2TB limit' do
          let(:options) { { generate_invoice: true, storage_size: 10_000_000_000_000 } }

          it { is_expected.to eq({ storage_fee: 0, invoice_fee: 199, total: 199 }) }
        end
      end
    end
  end
end

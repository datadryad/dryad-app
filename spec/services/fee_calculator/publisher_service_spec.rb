module FeeCalculator
  describe PublisherService do

    describe '#fee_calculator' do
      let(:options) { {} }
      let(:for_dataset) { false }
      subject { described_class.new(options, for_dataset: for_dataset).call }

      context 'without covering large dataset fee' do
        context 'without any configuration' do
          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000 }) }
        end

        context 'with dpc tier' do
          let(:options) { { dpc_tier: 3 } }

          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 2_700, total: 3_700 }) }
        end

        # TODO: do we raise an error in this case? or add 0
        context 'with dpc tier over limit' do
          let(:options) { { dpc_tier: 17 } }

          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000 }) }
        end

        context 'with service tier' do
          let(:options) { { service_tier: 5 } }

          it { is_expected.to eq({ service_fee: 10_000, dpc_fee: 0, total: 10_000 }) }
        end

        context 'with storage usage percents' do
          let(:options) { { storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

          # Does not return storage_by_tier
          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000 }) }
        end

        context 'with dpc and storage usage percents' do
          let(:options) { { dpc_tier: 10, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

          # Does not return storage_by_tier
          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 30_250, total: 31_250 }) }
        end

        context 'with service tier and dpc_tier' do
          let(:options) { { service_tier: 5, dpc_tier: 13 } }

          it { is_expected.to eq({ service_fee: 10_000, dpc_fee: 44_000, total: 54_000 }) }
        end
      end

      context 'covering large dataset fee' do
        let(:options) { { cover_storage_fee: true } }
        context 'without any configuration' do
          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000 }) }
        end

        context 'with dpc tier' do
          let(:options) { { cover_storage_fee: true, dpc_tier: 3 } }

          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 2_700, total: 3_700 }) }
        end

        # TODO: do we raise an error in this case? or add 0
        context 'with dpc tier over limit' do
          let(:options) { { cover_storage_fee: true, dpc_tier: 17 } }

          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000 }) }
        end

        context 'with service tier' do
          let(:options) { { cover_storage_fee: true, service_tier: 5 } }

          it { is_expected.to eq({ service_fee: 10_000, dpc_fee: 0, total: 10_000 }) }
        end

        context 'with storage usage percents' do
          let(:options) { { cover_storage_fee: true, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

          it {
            is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 6_029,
                                storage_by_tier: { 1 => 259, 2 => 464, 4 => 4_306 } })
          }
        end

        context 'with dpc and storage usage percents' do
          let(:options) { { cover_storage_fee: true, dpc_tier: 10, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

          # it would be using same values but multiplied with round(percent * range max)
          it {
            is_expected.to eq({ service_fee: 1_000, dpc_fee: 30_250, total: 362_972,
                                storage_by_tier: { 1 => 30 * 259, 2 => 30 * 464, 4 => 144 * 2_153 } })
          }
        end

        context 'with service tier and dpc_tier' do
          let(:options) { { cover_storage_fee: true, service_tier: 5, dpc_tier: 13 } }

          it { is_expected.to eq({ service_fee: 10_000, dpc_fee: 44_000, total: 54_000 }) }
        end
      end

    end
  end
end

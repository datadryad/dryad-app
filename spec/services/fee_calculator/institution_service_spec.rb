module FeeCalculator
  describe InstitutionService do

    describe '#fee_calculator' do
      let(:options) { {} }
      let(:for_dataset) { false }
      subject { described_class.new(options, for_dataset: for_dataset).call }

      context 'without any configuration' do
        it { is_expected.to eq({ service_fee: 5_000, dpc_fee: 0, total: 5_000 }) }
      end

      context 'with dpc tier' do
        let(:options) { { dpc_tier: 3 } }

        it { is_expected.to eq({ service_fee: 5_000, dpc_fee: 2_700, total: 7_700 }) }
      end

      # TODO: do we raise an error in this case? or add 0
      context 'with dpc tier over limit' do
        let(:options) { { dpc_tier: 17 } }

        it { is_expected.to eq({ service_fee: 5_000, dpc_fee: 0, total: 5_000 }) }
      end

      context 'with service tier' do
        let(:options) { { service_tier: 5 } }

        it { is_expected.to eq({ service_fee: 40_000, dpc_fee: 0, total: 40_000 }) }
      end

      context 'with storage usage percents' do
        let(:options) { { storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

        it {
          is_expected.to eq({ service_fee: 5_000, dpc_fee: 0, total: 10_029,
                              storage_by_tier: { 1 => 259, 2 => 464, 4 => 4_306 } })
        }
      end

      context 'with dpc and storage usage percents' do
        let(:options) { { dpc_tier: 10, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

        # it would be using same values but multiplied with round(percent * range max)
        it {
          is_expected.to eq({ service_fee: 5_000, dpc_fee: 30_250, total: 366_972,
                              storage_by_tier: { 1 => 30 * 259, 2 => 30 * 464, 4 => 144 * 2_153 } })
        }
      end

      context 'with service tier and dpc_tier' do
        let(:options) { { service_tier: 5, dpc_tier: 13 } }

        it { is_expected.to eq({ service_fee: 40_000, dpc_fee: 44_000, total: 84_000 }) }
      end

      context 'for low or middle income countries' do
        let(:options) { { low_middle_income_country: true } }

        it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000 }) }

        context 'with dpc tier' do
          let(:options) { { low_middle_income_country: true, dpc_tier: 3 } }

          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 2_700, total: 3_700 }) }
        end

        context 'with service tier' do
          let(:options) { { low_middle_income_country: true, service_tier: 5 } }

          it { is_expected.to eq({ service_fee: 7_500, dpc_fee: 0, total: 7_500 }) }
        end

        context 'with storage usage percents' do
          let(:options) { { low_middle_income_country: true, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

          it {
            is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 6_029,
                                storage_by_tier: { 1 => 259, 2 => 464, 4 => 4_306 } })
          }
        end

        context 'with dpc and storage usage percents' do
          let(:options) { { low_middle_income_country: true, dpc_tier: 10, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

          # it would be using same values but multiplied with round(percent * range max)
          it {
            is_expected.to eq({ service_fee: 1_000, dpc_fee: 30_250, total: 362_972,
                                storage_by_tier: { 1 => 30 * 259, 2 => 30 * 464, 4 => 144 * 2_153 } })
          }
        end

        context 'with service tier and dpc_tier' do
          let(:options) { { low_middle_income_country: true, service_tier: 5, dpc_tier: 13 } }

          it { is_expected.to eq({ service_fee: 7_500, dpc_fee: 44_000, total: 51_500 }) }
        end
      end

    end
  end
end

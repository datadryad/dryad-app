module FeeCalculator
  describe WaiverService do
    let(:options) { {} }
    let(:resource) { nil }
    let(:no_charges_response) { { storage_fee: 0, total: 0, storage_fee_label: 'Data Publishing Charge' } }

    subject { described_class.new(options, resource: resource).call }

    describe '#dataset fee_calculator' do
      let(:prev_files_size) { 0 }
      let(:new_files_size) { 100 }
      let(:identifier) { create(:identifier, last_invoiced_file_size: prev_files_size, payment_type: 'waiver') }

      context 'on first submit' do
        let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

        context 'without invoice fee' do
          context 'without any configuration' do
            it { is_expected.to eq(no_charges_response) }
          end

          context 'with storage_size at max limit' do
            let(:new_files_size) { 100_000_000_000 }

            it { is_expected.to eq(no_charges_response) }
          end

          context 'with storage_size over 2TB limit' do
            let(:new_files_size) { 10_000_000_000_000 }

            it 'raises an error' do
              expect { subject }.to raise_error(ActionController::BadRequest, OUT_OF_RANGE_MESSAGE)
            end
          end
        end
      end

      context 'on second submit' do
        let(:prev_files_size) { 100 }
        let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

        context 'without invoice fee' do
          context 'when files_size do not change' do
            it { is_expected.to eq(no_charges_response) }
          end

          context 'when files_size changes' do
            context 'but does not exceed the current limit' do
              let(:new_files_size) { 5_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'storage gets to next level' do
              let(:new_files_size) { 5_000_000_001 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'storage jumps a few levels' do
              let(:new_files_size) { 250_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'when storage changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'with storage_size over 2TB limit' do
              let(:new_files_size) { 10_000_000_000_000 }

              it 'raises an error' do
                expect { subject }.to raise_error(ActionController::BadRequest, OUT_OF_RANGE_MESSAGE)
              end
            end
          end
        end
      end
    end
  end
end

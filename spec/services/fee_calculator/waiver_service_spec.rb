module FeeCalculator
  describe WaiverService do
    let(:options) { {} }
    let(:resource) { nil }
    let(:no_charges_response) { { storage_fee: 0, total: 0, storage_fee_label: 'Data Publishing Charge' } }
    let(:coupon_id) { 'FEE_WAIVER_DISCOUNT' }

    subject { described_class.new(options, resource: resource).call }

    before do
      stub_const 'FeeCalculator::WaiverService::DISCOUNT_STORAGE_COUPON_ID', coupon_id
      stub_const 'FeeCalculator::WaiverService::FREE_STORAGE_SIZE', 10_000_000_000 # 10GB
    end

    describe '#dataset fee_calculator' do
      let(:prev_files_size) { 0 }
      let(:new_files_size) { 100 }
      let(:identifier) { create(:identifier, last_invoiced_file_size: prev_files_size, payment_type: 'waiver') }

      context 'without invoice flag' do
        context 'on first submit' do
          let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

          context 'without any configuration' do
            it { is_expected.to eq(no_charges_response) }
          end

          context 'with storage_size at max free limit' do
            let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE }

            it { is_expected.to eq(no_charges_response) }
          end

          context 'with storage_size over the max free limit' do
            let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE + 1 }

            it do
              is_expected.to eq(
                {
                  storage_fee: 340,
                  storage_fee_label: 'Data Publishing Charge',
                  coupon_id: coupon_id,
                  waiver_discount: -180,
                  total: 160
                }
              )
            end
          end

          it_behaves_like 'it has 1TB max limit'
        end

        context 'on second submit' do
          let(:prev_files_size) { 100 }
          let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

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
              let(:new_files_size) { 10_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'with storage_size at max free limit' do
              let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'with storage_size over the max free limit' do
              let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE + 1 }

              it do
                is_expected.to eq(
                  {
                    storage_fee: 340,
                    storage_fee_label: 'Data Publishing Charge',
                    coupon_id: coupon_id,
                    waiver_discount: -180,
                    total: 160
                  }
                )
              end
            end

            it_behaves_like 'it has 1TB max limit'
          end

          context 'when discount was previously applied' do
            let(:prev_files_size) { 15_000_000_000 }
            let!(:payment) { create(:resource_payment, resource: resource, has_discount: true) }

            context 'but does not exceed the current limit' do
              let(:new_files_size) { 50_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'storage gets to next level does not add discount again' do
              let(:new_files_size) { 50_000_000_001 }

              it { is_expected.to eq({ storage_fee: 288, storage_fee_label: 'Data Publishing Charge', total: 288 }) }
            end

            it_behaves_like 'it has 1TB max limit'
          end
        end
      end

      context 'with invoice flag' do
        let(:options) { { generate_invoice: true } }

        context 'on first submit' do
          let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

          context 'without any configuration' do
            it { is_expected.to eq(no_charges_response) }
          end

          context 'with storage_size at max free limit' do
            let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE }

            it { is_expected.to eq(no_charges_response) }
          end

          context 'with storage_size over the max free limit' do
            let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE + 1 }

            it do
              is_expected.to eq(
                {
                  storage_fee: 340,
                  storage_fee_label: 'Data Publishing Charge',
                  coupon_id: coupon_id,
                  waiver_discount: -180,
                  invoice_fee: 199,
                  total: 359
                }
              )
            end
          end

          it_behaves_like 'it has 1TB max limit'
        end

        context 'on second submit' do
          let(:prev_files_size) { 100 }
          let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

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
              let(:new_files_size) { 10_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'with storage_size at max free limit' do
              let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'with storage_size over the max free limit' do
              let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE + 1 }

              it do
                is_expected.to eq(
                  {
                    storage_fee: 340,
                    storage_fee_label: 'Data Publishing Charge',
                    coupon_id: coupon_id,
                    waiver_discount: -180,
                    invoice_fee: 199,
                    total: 359
                  }
                )
              end
            end

            it_behaves_like 'it has 1TB max limit'
          end

          context 'when discount was previously applied' do
            let(:prev_files_size) { 15_000_000_000 }
            let!(:payment) { create(:resource_payment, resource: resource, has_discount: true) }

            context 'but does not exceed the current limit' do
              let(:new_files_size) { 50_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'storage gets to next level does not add discount again' do
              let(:new_files_size) { 50_000_000_001 }

              it { is_expected.to eq({ storage_fee: 288, storage_fee_label: 'Data Publishing Charge', invoice_fee: 199, total: 487 }) }
            end

            it_behaves_like 'it has 1TB max limit'
          end
        end
      end
    end
  end
end

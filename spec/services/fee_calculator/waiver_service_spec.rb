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

    def no_charge_response(amount)
      charge_response(amount, amount)
    end

    def charge_response(amount, discount, invoice_fee: false)
      res = {
        storage_fee: amount,
        storage_fee_label: 'Data Publishing Charge',
        coupon_id: coupon_id,
        waiver_discount: -discount,
        total: amount - discount
      }
      if invoice_fee
        res[:invoice_fee] = 199
        res[:total] += 199
      end
      res
    end

    def no_discount_response(amount, invoice_fee: false)
      res = {
        storage_fee: amount,
        storage_fee_label: 'Data Publishing Charge',
        total: amount
      }
      if invoice_fee
        res[:invoice_fee] = 199
        res[:total] += 199
      end
      res
    end

    describe '#dataset fee_calculator' do
      let(:prev_files_size) { nil }
      let(:new_files_size) { 100 }
      let(:identifier) { create(:identifier, last_invoiced_file_size: prev_files_size, payment_type: 'waiver') }

      context 'without invoice flag' do
        context 'on first submit' do
          let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

          context 'without any configuration' do
            it { is_expected.to eq(no_charge_response(150)) }
          end

          context 'with storage_size at max free limit' do
            let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE }

            it { is_expected.to eq(no_charge_response(180)) }
          end

          context 'with storage_size over the max free limit' do
            let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE + 1 }

            it { is_expected.to eq(charge_response(520, 180)) }
          end

          it_behaves_like 'it has 1TB max limit'
        end

        context 'on second submit' do
          let(:prev_files_size) { 100 }
          let(:first_resource) { create(:resource, identifier: identifier, total_file_size: prev_files_size, created_at: 2.minutes.ago) }
          let!(:payment) { create(:resource_payment, resource: first_resource, has_discount: true) }
          let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

          context 'when files_size do not change' do
            it { is_expected.to eq(no_charges_response) }
          end

          context 'when paid for 0B' do
            let(:prev_files_size) { 0 }

            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end
          end

          context 'when files_size changes' do
            context 'but does not exceed the current limit' do
              let(:new_files_size) { 5_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'storage gets to next level' do
              let(:new_files_size) { 5_000_000_001 }

              it { is_expected.to eq(no_discount_response(0)) }
            end

            context 'storage jumps a few levels' do
              let(:new_files_size) { 60_000_000_000 }

              it { is_expected.to eq(no_discount_response(808 - 180)) }
            end

            context 'with storage_size at max free limit' do
              let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE }

              it { is_expected.to eq(no_discount_response(0)) }
            end

            context 'with storage_size over the max free limit' do
              let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE + 1 }

              it { is_expected.to eq(no_discount_response(520 - 180)) }
            end

            it_behaves_like 'it has 1TB max limit'
          end

          context 'when discount was previously applied' do
            let(:prev_files_size) { 15_000_000_000 }
            let(:first_resource) { create(:resource, identifier: identifier, total_file_size: prev_files_size, created_at: 2.minutes.ago) }
            let!(:payment) { create(:resource_payment, resource: first_resource, has_discount: true) }

            context 'but does not exceed the current limit' do
              let(:new_files_size) { 50_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'storage gets to next level does not add discount again' do
              let(:new_files_size) { 50_000_000_001 }

              it { is_expected.to eq(no_discount_response(808 - 520)) }
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
            it { is_expected.to eq(no_charge_response(150)) }
          end

          context 'with storage_size at max free limit' do
            let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE }

            it { is_expected.to eq(no_charge_response(180)) }
          end

          context 'with storage_size over the max free limit' do
            let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE + 1 }

            it { is_expected.to eq(charge_response(520, 180, invoice_fee: true)) }
          end

          it_behaves_like 'it has 1TB max limit'
        end

        context 'on second submit' do
          let(:prev_files_size) { 100 }
          let(:first_resource) { create(:resource, identifier: identifier, total_file_size: prev_files_size, created_at: 2.minutes.ago) }
          let!(:payment) { create(:resource_payment, resource: first_resource, has_discount: true) }
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
              let(:new_files_size) { 60_000_000_000 }

              it { is_expected.to eq(no_discount_response(808 - 180, invoice_fee: true)) }
            end

            context 'with storage_size at max free limit' do
              let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'with storage_size over the max free limit' do
              let(:new_files_size) { FeeCalculator::WaiverService::FREE_STORAGE_SIZE + 1 }

              it { is_expected.to eq(no_discount_response(520 - 180, invoice_fee: true)) }
            end

            it_behaves_like 'it has 1TB max limit'
          end

          context 'when discount was previously applied' do
            let(:prev_files_size) { 15_000_000_000 }
            let(:first_resource) { create(:resource, identifier: identifier, total_file_size: prev_files_size, created_at: 2.minutes.ago) }
            let!(:payment) { create(:resource_payment, resource: first_resource, has_discount: true) }

            context 'but does not exceed the current limit' do
              let(:new_files_size) { 50_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'storage gets to next level does not add discount again' do
              let(:new_files_size) { 50_000_000_001 }

              it { is_expected.to eq(no_discount_response(808 - 520, invoice_fee: true)) }
            end

            it_behaves_like 'it has 1TB max limit'
          end
        end
      end
    end
  end
end

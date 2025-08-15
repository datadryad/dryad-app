module FeeCalculator
  describe IndividualService do
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe

    let(:options) { {} }
    let(:resource) { nil }
    let(:no_charges_response) { { storage_fee: 0, total: 0 } }

    subject { described_class.new(options, resource: resource).call.except(:storage_fee_label) }

    before do
      mock_solr!
      mock_salesforce!
      mock_stripe!
    end

    describe '#fee_calculator' do
      context 'without invoice fee' do
        it 'has proper storage fee label' do
          expect(described_class.new(options, resource: resource).call[:storage_fee_label]).to eq('Data Publishing Charge')
        end

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

        it_behaves_like 'it has 1TB max limit based on options'
      end

      context 'with ppr fee' do
        it 'has proper storage fee label' do
          expect(described_class.new(options, resource: resource).call[:storage_fee_label]).to eq('Data Publishing Charge')
        end

        context 'without any configuration' do
          let(:options) { { pay_ppr_fee: true } }

          it { is_expected.to eq({ ppr_fee: 50, total: 50 }) }
        end

        context 'with storage_size at max limit' do
          let(:options) { { pay_ppr_fee: true, storage_size: 100_000_000_000 } }

          it { is_expected.to eq({ ppr_fee: 50, total: 50 }) }
        end

        context 'with storage_size as min limit' do
          let(:options) { { pay_ppr_fee: true, storage_size: 100_000_000_001 } }

          it { is_expected.to eq({ ppr_fee: 50, total: 50 }) }
        end

        it_behaves_like 'it has 1TB max limit based on options', { pay_ppr_fee: true }
      end

      context 'with invoice fee' do
        it 'has proper storage fee label' do
          expect(described_class.new(options, resource: resource).call[:storage_fee_label]).to eq('Data Publishing Charge')
        end

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

        it_behaves_like 'it has 1TB max limit based on options', { generate_invoice: true }
      end
    end

    describe '#dataset fee_calculator' do
      let(:prev_files_size) { nil }
      let(:new_files_size) { 100 }
      let(:identifier) { create(:identifier, last_invoiced_file_size: prev_files_size) }

      context 'on first submit' do
        let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

        context 'without invoice fee' do
          it 'has proper storage fee label' do
            expect(described_class.new(options, resource: resource).call[:storage_fee_label]).to eq('Data Publishing Charge')
          end

          context 'without any configuration' do
            it { is_expected.to eq({ storage_fee: 150, total: 150 }) }
          end

          context 'with storage_size at max limit' do
            let(:new_files_size) { 100_000_000_000 }

            it { is_expected.to eq({ storage_fee: 808, total: 808 }) }
          end

          context 'with storage_size as min limit' do
            let(:new_files_size) { 100_000_000_001 }

            it { is_expected.to eq({ storage_fee: 1_750, total: 1_750 }) }
          end

          it_behaves_like 'it has 1TB max limit'
        end

        context 'with ppr fee' do
          let(:options) { { pay_ppr_fee: true } }

          context 'without any configuration' do
            it { is_expected.to eq({ ppr_fee: 50, total: 50 }) }
          end

          context 'with storage_size at max limit' do
            let(:new_files_size) { 100_000_000_000 }

            it { is_expected.to eq({ ppr_fee: 50, total: 50 }) }
          end

          context 'with storage_size as min limit' do
            let(:new_files_size) { 100_000_000_001 }

            it { is_expected.to eq({ ppr_fee: 50, total: 50 }) }
          end

          it_behaves_like 'it has 1TB max limit'
        end

        context 'with invoice fee' do
          let(:options) { { generate_invoice: true } }

          context 'without any configuration' do
            it { is_expected.to eq({ storage_fee: 150, invoice_fee: 199, total: 349 }) }
          end

          context 'with storage_size at max limit' do
            let(:new_files_size) { 100_000_000_000 }

            it { is_expected.to eq({ storage_fee: 808, invoice_fee: 199, total: 1007 }) }
          end

          context 'with storage_size as min limit' do
            let(:new_files_size) { 100_000_000_001 }

            it { is_expected.to eq({ storage_fee: 1_750, invoice_fee: 199, total: 1949 }) }
          end

          it_behaves_like 'it has 1TB max limit'
        end
      end

      context 'on second submit' do
        let(:prev_files_size) { 100 }
        let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

        context 'when paid for 0B' do
          let(:prev_files_size) { 0 }

          context 'when files_size do not change' do
            it { is_expected.to eq(no_charges_response) }
          end
        end

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

              it 'has proper storage fee label' do
                expect(described_class.new(options, resource: resource).call[:storage_fee_label]).to eq('Data Publishing Charge')
              end
              it { is_expected.to eq({ storage_fee: 30, total: 30 }) }
            end

            context 'storage jumps a few levels' do
              let(:new_files_size) { 250_000_000_000 }

              it { is_expected.to eq({ storage_fee: 1_600, total: 1_600 }) }
            end

            context 'when storage changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it { is_expected.to eq({ storage_fee: 5_269, total: 5_269 }) }
            end

            context 'when storage changes decrease from one tier to another' do
              let(:prev_files_size) { 100_000_000_001 }
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'when storage changes increase but the author already paid for the new tier' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 100_000_000_001 }
              let(:identifier) { create(:identifier, last_invoiced_file_size: 100_000_000_001) }

              it { is_expected.to eq(no_charges_response) }
            end

            it_behaves_like 'it has 1TB max limit'
          end
        end

        context 'with invoice fee' do
          let(:options) { { generate_invoice: true } }

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

              it 'has proper storage fee label' do
                expect(described_class.new(options, resource: resource).call[:storage_fee_label]).to eq('Data Publishing Charge')
              end

              it { is_expected.to eq({ storage_fee: 30, invoice_fee: 199, total: 229 }) }
            end

            context 'storage jumps a few levels' do
              let(:new_files_size) { 250_000_000_000 }

              it { is_expected.to eq({ storage_fee: 1_600, invoice_fee: 199, total: 1_799 }) }
            end

            context 'when storage changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it { is_expected.to eq({ storage_fee: 5_269, invoice_fee: 199, total: 5_468 }) }
            end

            context 'when storage changes decrease from one tier to another' do
              let(:prev_files_size) { 100_000_000_001 }
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            it_behaves_like 'it has 1TB max limit'
          end
        end

        context 'with ppr fee paid' do
          let(:prev_files_size) { nil }
          let(:coupon_id) { 'PPR_DISCOUNT_2025' }
          let(:first_resource) { create(:resource, total_file_size: new_files_size, identifier: identifier, created_at: 2.minutes.ago) }
          let!(:payment) { create(:resource_payment, resource: first_resource, ppr_fee_paid: true, amount: 50) }
          let(:resource) { create(:resource, total_file_size: new_files_size, identifier: identifier) }

          context 'when ppr continues' do
            let(:options) { { pay_ppr_fee: true } }

            it { is_expected.to eq({ coupon_id: coupon_id, ppr_fee: 50, ppr_discount: -50, total: 0 }) }
          end

          context 'when ppr is over' do
            it { is_expected.to eq({ coupon_id: coupon_id, storage_fee: 150, ppr_discount: -50, total: 100 }) }
          end

          it_behaves_like 'it has 1TB max limit'
        end
      end
    end
  end
end

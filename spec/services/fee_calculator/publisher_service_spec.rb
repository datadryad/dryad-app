module FeeCalculator
  describe PublisherService do
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe

    let(:options) { {} }
    let(:resource) { nil }
    let(:no_charges_response) { { service_fee: 0, dpc_fee: 0, storage_fee: 0, total: 0, storage_fee_label: 'Large data fee' } }

    subject { described_class.new(options, resource: resource).call.except(:storage_fee_label) }

    before do
      mock_solr!
      mock_salesforce!
      mock_stripe!
    end

    describe '#fee_calculator' do

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
          it {
            is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000,
                                storage_by_tier: { 1 => 259, 2 => 464, 4 => 6_459 } })
          }
        end

        context 'with dpc and storage usage percents' do
          let(:options) { { dpc_tier: 10, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

          # Does not return storage_by_tier
          it {
            is_expected.to eq({ service_fee: 1_000, dpc_fee: 30_250, total: 31_250,
                                storage_by_tier: { 1 => 7770, 2 => 13_920, 4 => 310_032 } })
          }
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
            is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 8_182,
                                storage_by_tier: { 1 => 259, 2 => 464, 4 => 6_459 } })
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

    describe '#dataset fee_calculator' do
      let(:prev_files_size) { nil }
      let(:new_files_size) { 100 }
      let(:covers_ldf) { false }
      let!(:journal) { create(:journal, payment_plan_type: '2025', covers_ldf: covers_ldf) }
      let(:identifier) { create(:identifier, last_invoiced_file_size: prev_files_size) }
      subject { described_class.new(options, resource: resource).call }

      context 'on first submit' do
        let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first], total_file_size: new_files_size) }

        context 'without invoice fee' do
          context 'when covers_ldf true' do
            let(:covers_ldf) { true }

            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes' do
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            it_behaves_like 'it has 2 TB max limit'
          end

          context 'when covers_ldf false' do
            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes under free tier limit' do
              let(:new_files_size) { 5_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes over free tier limit' do
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 464, total: 464, storage_fee_label: 'Large data fee' }) }
            end

            it_behaves_like 'it has 2 TB max limit'
          end
        end

        context 'with invoice fee' do
          context 'when covers_ldf true' do
            let(:covers_ldf) { true }
            let(:options) { { generate_invoice: true } }

            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes' do
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            it_behaves_like 'it has 2 TB max limit'
          end

          context 'when covers_ldf false' do
            let(:options) { { generate_invoice: true } }

            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes under free tier limit' do
              let(:new_files_size) { 5_000_000_000 }
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes over free tier limit' do
              let(:new_files_size) { 100_000_000_000 }

              it {
                is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 464, invoice_fee: 199, total: 663, storage_fee_label: 'Large data fee' })
              }
            end

            it_behaves_like 'it has 2 TB max limit'
          end
        end
      end

      context 'on second submit' do
        let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first], total_file_size: new_files_size) }

        context 'without invoice fee' do
          context 'when covers_ldf true' do
            let(:covers_ldf) { true }

            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes from free tier to another' do
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'when storage changes decrease from one tier to another' do
              let(:prev_files_size) { 100_000_000_001 }
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            it_behaves_like 'it has 2 TB max limit'
          end

          context 'when covers_ldf false' do
            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes from free tier to another' do
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 464, total: 464, storage_fee_label: 'Large data fee' }) }
            end

            context 'when files_size changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 3_883, total: 3_883, storage_fee_label: 'Large data fee' }) }
            end

            context 'when storage changes decrease from one tier to another' do
              let(:prev_files_size) { 100_000_000_001 }
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            it_behaves_like 'it has 2 TB max limit'
          end
        end

        context 'with invoice fee' do
          context 'when covers_ldf true' do
            let(:covers_ldf) { true }
            let(:options) { { generate_invoice: true } }

            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes under free tier limit' do
              let(:new_files_size) { 5_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes over free tier limit' do
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            context 'when storage changes decrease from one tier to another' do
              let(:prev_files_size) { 100_000_000_001 }
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            it_behaves_like 'it has 2 TB max limit'
          end

          context 'when covers_ldf false' do
            let(:options) { { generate_invoice: true } }

            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes from free tier to another' do
              let(:new_files_size) { 100_000_000_000 }

              it {
                is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 464, invoice_fee: 199, total: 663, storage_fee_label: 'Large data fee' })
              }
            end

            context 'when files_size changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it {
                is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 3_883, invoice_fee: 199, total: 4_082,
                                    storage_fee_label: 'Large data fee' })
              }
            end

            context 'when storage changes decrease from one tier to another' do
              let(:prev_files_size) { 100_000_000_001 }
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end

            it_behaves_like 'it has 2 TB max limit'
          end
        end
      end

      context 'when journal is a payer but not on 2025 fee model' do
        let!(:journal) { create(:journal, payment_plan_type: 'DEFERRED', covers_ldf: covers_ldf) }
        let(:resource) { create(:resource, identifier: identifier, journal_issns: [journal.issns.first], total_file_size: new_files_size) }

        it 'raises an error' do
          expect { subject }.to raise_error(ActionController::BadRequest, OLD_PAYMENT_SYSTEM_MESSAGE)
        end
      end

      context 'when payer is a funder' do
        let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }
        let(:contributor) do
          create(:contributor, contributor_name: 'National Cancer Institute',
                               contributor_type: 'funder', resource_id: resource.id)
        end

        context 'and is on 2025 fee model' do
          let!(:funder) { create(:funder, name: contributor.contributor_name, payment_plan: '2025', covers_dpc: true, enabled: true) }

          it { is_expected.to eq(no_charges_response) }
        end

        context 'not on 2025 fee model' do
          let!(:funder) { create(:funder, name: contributor.contributor_name, payment_plan: 'tiered', covers_dpc: true, enabled: true) }

          it 'raises an error' do
            expect { subject }.to raise_error(ActionController::BadRequest, OLD_PAYMENT_SYSTEM_MESSAGE)
          end
        end

        context 'on 2025 fee model but is not enabled' do
          let!(:funder) { create(:funder, name: contributor.contributor_name, payment_plan: '2025', covers_dpc: true, enabled: false) }

          it 'raises an error' do
            expect { subject }.to raise_error(ActionController::BadRequest, MISSING_PAYER_MESSAGE)
          end
        end

        context 'not on a payer' do
          let!(:funder) { create(:funder, name: contributor.contributor_name, payment_plan: nil, covers_dpc: false) }

          it 'raises an error' do
            expect { subject }.to raise_error(ActionController::BadRequest, MISSING_PAYER_MESSAGE)
          end
        end
      end
    end
  end
end

module FeeCalculator
  describe IndividualService do
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe

    let(:options) { {} }
    let(:resource) { nil }
    let(:no_charges_response) { { storage_fee: 0, total: 0 } }

    subject { described_class.new(options, resource: resource).call }

    before do
      mock_solr!
      mock_salesforce!
      mock_stripe!
    end

    describe '#fee_calculator' do
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

        context 'with storage_size over 2TB limit' do
          let(:options) { { storage_size: 10_000_000_000_000 } }

          it 'raises an error' do
            expect { subject }.to raise_error(ActionController::BadRequest, 'The value is out of defined range')
          end
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

        context 'with storage_size over 2TB limit' do
          let(:options) { { generate_invoice: true, storage_size: 10_000_000_000_000 } }

          it 'raises an error' do
            expect { subject }.to raise_error(ActionController::BadRequest, 'The value is out of defined range')
          end
        end
      end
    end

    describe '#dataset fee_calculator' do
      let(:prev_files_size) { 100 }
      let(:new_files_size) { 100 }
      let(:identifier) { create(:identifier, last_invoiced_file_size: prev_files_size) }

      context 'on first publish' do
        let(:resource) { create(:resource, identifier: identifier, total_file_size: new_files_size) }

        context 'without invoice fee' do
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

          context 'with storage_size over 2TB limit' do
            let(:new_files_size) { 10_000_000_000_000 }

            it 'raises an error' do
              expect { subject }.to raise_error(ActionController::BadRequest, 'The value is out of defined range')
            end
          end
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

          context 'with storage_size over 2TB limit' do
            let(:new_files_size) { 10_000_000_000_000 }

            it 'raises an error' do
              expect { subject }.to raise_error(ActionController::BadRequest, 'The value is out of defined range')
            end
          end
        end
      end

      context 'on second publish' do
        let(:prev_resource) { create(:resource, identifier: identifier, created_at: 1.second.ago) }
        let!(:ca) { create(:curation_activity, resource: prev_resource, status: 'published') }
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

            context 'with storage_size over 2TB limit' do
              let(:new_files_size) { 10_000_000_000_000 }

              it 'raises an error' do
                expect { subject }.to raise_error(ActionController::BadRequest, 'The value is out of defined range')
              end
            end
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

            context 'with storage_size over 2TB limit' do
              let(:new_files_size) { 10_000_000_000_000 }

              it 'raises an error' do
                expect { subject }.to raise_error(ActionController::BadRequest, 'The value is out of defined range')
              end
            end
          end
        end
      end
    end
  end
end

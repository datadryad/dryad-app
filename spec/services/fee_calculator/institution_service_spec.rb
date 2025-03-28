module FeeCalculator
  describe InstitutionService do
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe

    let(:options) { {} }
    let(:resource) { nil }
    let(:no_charges_response) { { service_fee: 0, dpc_fee: 0, storage_fee: 0, total: 0 } }

    subject { described_class.new(options, resource: resource).call }

    before do
      mock_solr!
      mock_salesforce!
      mock_stripe!
    end

    describe '#fee_calculator' do
      context 'without covering large dataset fee' do
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
            is_expected.to eq({ service_fee: 5_000, dpc_fee: 0, total: 5_000,
                                storage_by_tier: { 1 => 259, 2 => 464, 4 => 4_306 } })
          }
        end

        context 'with dpc and storage usage percents' do
          let(:options) { { dpc_tier: 10, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

          # it would be using same values but multiplied with round(percent * range max)
          it {
            is_expected.to eq({ service_fee: 5_000, dpc_fee: 30_250, total: 35_250,
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
              is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000,
                                  storage_by_tier: { 1 => 259, 2 => 464, 4 => 4_306 } })
            }
          end

          context 'with dpc and storage usage percents' do
            let(:options) { { low_middle_income_country: true, dpc_tier: 10, storage_usage: { 1 => 10, 2 => 10, 4 => 48 } } }

            # it would be using same values but multiplied with round(percent * range max)
            it {
              is_expected.to eq({ service_fee: 1_000, dpc_fee: 30_250, total: 31_250,
                                  storage_by_tier: { 1 => 30 * 259, 2 => 30 * 464, 4 => 144 * 2_153 } })
            }
          end

          context 'with service tier and dpc_tier' do
            let(:options) { { low_middle_income_country: true, service_tier: 5, dpc_tier: 13 } }

            it { is_expected.to eq({ service_fee: 7_500, dpc_fee: 44_000, total: 51_500 }) }
          end
        end
      end

      context 'covering large dataset fee' do
        context 'without any configuration' do
          let(:options) { { cover_storage_fee: true } }
          it { is_expected.to eq({ service_fee: 5_000, dpc_fee: 0, total: 5_000 }) }
        end

        context 'with dpc tier' do
          let(:options) { { dpc_tier: 3, cover_storage_fee: true } }

          it { is_expected.to eq({ service_fee: 5_000, dpc_fee: 2_700, total: 7_700 }) }
        end

        # TODO: do we raise an error in this case? or add 0
        context 'with dpc tier over limit' do
          let(:options) { { dpc_tier: 17, cover_storage_fee: true } }

          it { is_expected.to eq({ service_fee: 5_000, dpc_fee: 0, total: 5_000 }) }
        end

        context 'with service tier' do
          let(:options) { { service_tier: 5, cover_storage_fee: true } }

          it { is_expected.to eq({ service_fee: 40_000, dpc_fee: 0, total: 40_000 }) }
        end

        context 'with storage usage percents' do
          let(:options) { { storage_usage: { 1 => 10, 2 => 10, 4 => 48 }, cover_storage_fee: true } }

          it {
            is_expected.to eq({ service_fee: 5_000, dpc_fee: 0, total: 10_029,
                                storage_by_tier: { 1 => 259, 2 => 464, 4 => 4_306 } })
          }
        end

        context 'with dpc and storage usage percents' do
          let(:options) { { dpc_tier: 10, storage_usage: { 1 => 10, 2 => 10, 4 => 48 }, cover_storage_fee: true } }

          # it would be using same values but multiplied with round(percent * range max)
          it {
            is_expected.to eq({ service_fee: 5_000, dpc_fee: 30_250, total: 366_972,
                                storage_by_tier: { 1 => 30 * 259, 2 => 30 * 464, 4 => 144 * 2_153 } })
          }
        end

        context 'with service tier and dpc_tier' do
          let(:options) { { service_tier: 5, dpc_tier: 13, cover_storage_fee: true } }

          it { is_expected.to eq({ service_fee: 40_000, dpc_fee: 44_000, total: 84_000 }) }
        end

        context 'for low or middle income countries' do
          let(:options) { { low_middle_income_country: true, cover_storage_fee: true } }

          it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 1_000 }) }

          context 'with dpc tier' do
            let(:options) { { low_middle_income_country: true, dpc_tier: 3, cover_storage_fee: true } }

            it { is_expected.to eq({ service_fee: 1_000, dpc_fee: 2_700, total: 3_700 }) }
          end

          context 'with service tier' do
            let(:options) { { low_middle_income_country: true, service_tier: 5, cover_storage_fee: true } }

            it { is_expected.to eq({ service_fee: 7_500, dpc_fee: 0, total: 7_500 }) }
          end

          context 'with storage usage percents' do
            let(:options) { { low_middle_income_country: true, storage_usage: { 1 => 10, 2 => 10, 4 => 48 }, cover_storage_fee: true } }

            it {
              is_expected.to eq({ service_fee: 1_000, dpc_fee: 0, total: 6_029,
                                  storage_by_tier: { 1 => 259, 2 => 464, 4 => 4_306 } })
            }
          end

          context 'with dpc and storage usage percents' do
            let(:options) do
              {
                low_middle_income_country: true, dpc_tier: 10,
                cover_storage_fee: true,
                storage_usage: { 1 => 10, 2 => 10, 4 => 48 }
              }
            end

            it {
              is_expected.to eq({ service_fee: 1_000, dpc_fee: 30_250, total: 362_972,
                                  storage_by_tier: { 1 => 7770, 2 => 13_920, 4 => 310_032 } })
            }
          end

          context 'with service tier and dpc_tier' do
            let(:options) { { low_middle_income_country: true, service_tier: 5, dpc_tier: 13, cover_storage_fee: true } }

            it { is_expected.to eq({ service_fee: 7_500, dpc_fee: 44_000, total: 51_500 }) }
          end
        end
      end
    end

    describe '#dataset fee_calculator' do
      let(:prev_files_size) { 0 }
      let(:new_files_size) { 100 }
      let(:covers_ldf) { false }
      let!(:tenant) { create(:tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: covers_ldf) }
      let(:identifier) { create(:identifier, last_invoiced_file_size: prev_files_size) }

      context 'on first publish' do
        let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: new_files_size) }

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

            context 'with storage_size over 2TB limit' do
              let(:new_files_size) { 10_000_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end
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

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 464, total: 464 }) }
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

            context 'with storage_size over 2TB limit' do
              let(:new_files_size) { 10_000_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end
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

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 464, invoice_fee: 199, total: 663 }) }
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

      context 'on second publish' do
        let(:prev_resource) { create(:resource, identifier: identifier, tenant: tenant, created_at: 1.second.ago) }
        let!(:ca) { create(:curation_activity, resource: prev_resource, status: 'published') }
        let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: new_files_size) }

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

            context 'with storage_size over 2TB limit' do
              let(:new_files_size) { 10_000_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end
          end

          context 'when covers_ldf false' do
            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes from free tier to another' do
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 464, total: 464 }) }
            end

            context 'when files_size changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 3_883, total: 3_883 }) }
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

            context 'with storage_size over 2TB limit' do
              let(:new_files_size) { 10_000_000_000_000 }

              it { is_expected.to eq(no_charges_response) }
            end
          end

          context 'when covers_ldf false' do
            let(:options) { { generate_invoice: true } }

            context 'when files_size do not change' do
              it { is_expected.to eq(no_charges_response) }
            end

            context 'when files_size changes from free tier to another' do
              let(:new_files_size) { 100_000_000_000 }

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 464, invoice_fee: 199, total: 663 }) }
            end

            context 'when files_size changes from non free tier to another' do
              let(:prev_files_size) { 100_000_000_000 }
              let(:new_files_size) { 900_000_000_000 }

              it { is_expected.to eq({ service_fee: 0, dpc_fee: 0, storage_fee: 3_883, invoice_fee: 199, total: 4_082 }) }
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

      context 'when tenant is a payer but not on 2025 fee model' do
        let!(:tenant) { create(:tenant, payment_plan: 'tiered', covers_dpc: true, covers_ldf: covers_ldf) }
        let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: new_files_size) }

        it 'raises an error' do
          expect { subject }.to raise_error(ActionController::BadRequest, 'Payer is not on 2025 payment plan')
        end
      end

      context 'when tenant is not a payer' do
        let!(:tenant) { create(:tenant, payment_plan: 'tiered', covers_dpc: false, covers_ldf: covers_ldf) }
        let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: new_files_size) }

        it 'raises an error' do
          expect { subject }.to raise_error(ActionController::BadRequest, 'Payer is not on 2025 payment plan')
        end
      end
    end
  end
end

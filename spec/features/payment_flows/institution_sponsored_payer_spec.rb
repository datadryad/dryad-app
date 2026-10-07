RSpec.feature 'Institution sponsored PaymentFlows', type: :feature, js: true do
  include DatasetHelper
  include PaymentsHelper
  include Mocks::RSolr
  include Mocks::Aws
  include Mocks::DataFile
  include Mocks::Stripe

  let(:tenant) { create(:tenant) }
  let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true) }
  let(:payer_name) { tenant.long_name }
  let(:user) { create(:user, tenant: tenant) }
  let(:resource_file_size) { 10 }

  before do
    mock_solr_frontend!
    mock_aws!
    mock_file_content!
    mock_stripe!

    tenant.reload
    payment_conf.reload

    sign_in(user)
  end

  describe 'on first version' do
    before do
      start_new_dataset
      build_min_dataset(resource_file_size: resource_file_size)
    end

    context 'payment value' do
      it 'user does not pay DPC' do
        expect(page).to have_content('All data publishing fees are covered by your sponsorship.')
        expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
      end

      context 'when LDF is not covered' do
        let(:resource_file_size) { 53_200_000_000 }

        it 'user pays LDF value' do
          expect(page).to have_content('This 53.2 GB dataset has a Large Data Fee of $464.00.')
          expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
          expect(page).to have_css('button', exact_text: 'Pay & submit for publication')
        end
      end

      context 'when LDF is covered' do
        let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true) }
        let(:resource_file_size) { 53_200_000_000 }

        it 'sponsored user does not pay anything' do
          expect(page).to have_content('All data publishing fees are covered by your sponsorship.')
          expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
          expect(page).to have_css('button', exact_text: 'Submit for publication')
        end

        context 'and limited by size' do
          let!(:payment_conf) do
            create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true,
                                           covers_ldf: true, ldf_limit: 2)
          end

          context 'dataset is under the limit' do
            let(:resource_file_size) { 13_200_000_000 }

            it 'sponsored user does not pay anything' do
              expect(page).to have_content('All data publishing fees are covered by your sponsorship.')
              expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
              expect(page).to have_css('button', exact_text: 'Submit for publication')
            end
          end

          context 'dataset is over the limit' do
            let(:resource_file_size) { 123_200_000_000 }

            it 'user pays only the difference' do
              expect(page).to have_content('This 123.2 GB dataset has a Large Data Fee of $659.00')
              expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
              expect(page).to have_css('button', exact_text: 'Pay & submit for publication')
            end
          end
        end

        context 'and limited by yearly amount' do
          let!(:payment_conf) do
            create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true,
                                           covers_ldf: true, yearly_ldf_limit: 1_000)
          end

          context 'dataset is under the limit' do
            let(:resource_file_size) { 53_200_000_000 }

            it 'sponsored user does not pay anything' do
              expect(page).to have_content('All data publishing fees are covered by your sponsorship.')
              expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
            end
          end

          context 'dataset is over the limit' do
            let(:resource_file_size) { 123_200_000_000 }

            it 'user pays the entire amount' do
              expect(page).to have_content('This 123.2 GB dataset has a Large Data Fee of $1,123.00')
              expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
            end
          end
        end
      end

      context 'when payer is not on 2025' do
        context 'all is sponsored' do
          let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: 'TIERED', covers_dpc: true, covers_ldf: false) }
          let(:resource_file_size) { 153_200_000_000 }

          it 'sponsored user does not pay anything' do
            expect(page).not_to have_content('Large Data Fee')
            expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
            expect(page).to have_css('button', exact_text: 'Submit for publication')
          end
        end
      end
    end
  end

  describe 'on second version' do
    let(:last_invoiced_file_size) { 34 }
    let(:resource_file_size) { 10 }
    let!(:identifier) do
      create(:identifier, payment_type: 'institution-2025', payment_id: tenant.id,
                          last_invoiced_file_size: last_invoiced_file_size, license_id: :cc0)
    end
    let(:resource) do
      create(:resource, identifier: identifier, user: user, accepted_agreement: true,
                        created_at: 1.minute.ago, total_file_size: last_invoiced_file_size)
    end

    before do
      create(:description, resource: resource, description_type: 'technicalinfo')
      create(:description, resource: resource, description_type: 'hsi_statement', description: nil)
      create(:description, resource: resource, description_type: 'abstract', description: 'Abstract')

      create(:data_file, resource: resource, download_filename: 'file1.txt', file_state: 'created', upload_file_size: 1000)
      create(:data_file, resource: resource, download_filename: 'README.md', file_state: 'created', upload_file_size: 100)

      CurationService.new(user: user, resource: resource, status: 'queued').process
      resource.current_state = :submitted

      identifier.reload
      resource.reload

      click_link 'My datasets'
      click_button 'Revise submission'

      expect(page).to have_content('Dataset submission')
      identifier.update!(last_invoiced_file_size: last_invoiced_file_size)
      visit current_path
    end

    context 'payment value' do
      context 'ldf is not covered' do
        context 'when nothing changes' do
          it 'user pays nothing and no LDF log created' do
            sponsored_no_fee
            no_ldf
          end
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview'
          end

          context 'and LDF tier is not exceeded' do
            it 'user pays nothing and no LDF log created' do
              sponsored_no_fee
              no_ldf
            end
          end

          context 'and LDF tier is exceeded' do
            let(:resource_file_size) { 20_000_000_000 }

            it 'user pays and no LDF log created' do
              sponsored_with_fee('20 GB', '259.00')
              pays_and_no_ldf
            end
          end
        end
      end

      context 'ldf is covered but not limited' do
        let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true) }

        context 'when nothing changes' do
          it 'user pays nothing and no LDF log created' do
            sponsored_no_fee
            no_ldf
          end
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview'
          end

          context 'and tier is not changed' do
            it 'user pays nothing and no LDF log created' do
              sponsored_no_fee
              no_ldf
            end
          end

          context 'and tier is changed' do
            let(:resource_file_size) { 53_200_000_000 }

            it 'user pays nothing and LDF log is created' do
              sponsored_no_fee
              logs_ldf(464)
            end
          end
        end
      end

      context 'ldf is covered and limited by size' do
        let!(:payment_conf) do
          create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true,
                                         ldf_limit: 2)
        end

        context 'when nothing changes' do
          it 'user pays nothing and no LDF log created' do
            sponsored_no_fee
            no_ldf
          end
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview'
          end

          context 'when limit tier is not changed' do
            let(:last_invoiced_file_size) { 20_000_000_000 }
            let(:resource_file_size) { 44_200_000_000 }

            it 'user pays nothing and no LDF log created' do
              sponsored_no_fee
              no_ldf
            end
          end

          context 'when limit tier is exceeded' do
            let(:resource_file_size) { 153_200_000_000 }

            it 'user pays and LDF log is created' do
              sponsored_with_fee('153.2 GB', '659.00')
              pays_and_logs_ldf(464)
            end
          end

          context 'when limit tier is not exceeded, logs only the difference' do
            let(:last_invoiced_file_size) { 12_000_000_000 }
            let(:resource_file_size) { 55_000_000_000 }

            it 'user pays nothing and LDF log is created' do
              sponsored_no_fee
              logs_ldf(205)
            end
          end
        end
      end

      context 'ldf is covered and limited by yearly amount' do
        let!(:payment_conf) do
          create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true,
                                         yearly_ldf_limit: 1_000)
        end

        context 'when nothing changes' do
          it 'user pays nothing and no LDF log created' do
            sponsored_no_fee
            no_ldf
          end
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview'
          end

          context 'and LDF tier is not changed' do
            let(:last_invoiced_file_size) { 20_000_000_000 }
            let(:resource_file_size) { 44_200_000_000 }

            it 'user pays nothing and no LDF log created' do
              sponsored_no_fee
              no_ldf
            end
          end

          context 'when yearly limit is exceeded' do
            let(:resource_file_size) { 153_200_000_000 }

            it 'user pays and no LDF log created' do
              sponsored_with_fee('153.2 GB', '1,123.00')
              pays_and_no_ldf
            end
          end

          context 'when LDF tier is exceeded, logs only the difference' do
            let(:last_invoiced_file_size) { 12_000_000_000 }
            let(:resource_file_size) { 55_000_000_000 }

            it 'user pays nothing and LDF log is created' do
              sponsored_no_fee
              logs_ldf(205)
            end
          end
        end
      end

      context 'ldf is covered and limited by size and yearly amount' do
        let!(:payment_conf) do
          create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true,
                                         ldf_limit: 2, yearly_ldf_limit: 1_000)
        end

        context 'when nothing changes' do
          it 'user pays nothing and no LDF log created' do
            sponsored_no_fee
            no_ldf
          end
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview'
          end

          context 'and LDF tier is not changed' do
            let(:last_invoiced_file_size) { 20_000_000_000 }
            let(:resource_file_size) { 44_200_000_000 }

            it 'user pays nothing and no LDF log created' do
              sponsored_no_fee
              no_ldf
            end
          end

          context 'when LDF limit will be exceeded, but yearly limit not' do
            let(:last_invoiced_file_size) { 12_200_000_000 }
            let(:resource_file_size) { 153_200_000_000 }

            it 'user pays and LDF log is created' do
              sponsored_with_fee('153.2 GB', '659.00')
              pays_and_logs_ldf(205)
            end
          end

          context 'when LDF limit is already exceeded, but yearly limit will not' do
            let(:last_invoiced_file_size) { 53_200_000_000 }
            let(:resource_file_size) { 153_200_000_000 }

            it 'user pays and no LDF log created' do
              sponsored_with_fee('153.2 GB', '659.00')
              pays_and_no_ldf
            end
          end

          context 'when LDF limit is exceeded, and yearly limit will be exceeded' do
            let(:last_invoiced_file_size) { 12_000_000_000 }
            let(:resource_file_size) { 153_200_000_000 }
            let!(:sponsored_payment_log) do
              create(:sponsored_payment_log, ldf: 900, resource: resource, payer: tenant, sponsor_id: tenant.id)
            end

            before do
              tenant.reload
              sponsored_payment_log.reload
              visit current_path
            end

            it 'user pays and no LDF log created' do
              sponsored_with_fee('153.2 GB', '864.00')
              pays_and_no_ldf
            end
          end
        end
      end

      context 'when payer is not on 2025' do
        before do
          upload_file(size: resource_file_size)
          click_button 'Preview'
        end

        context 'all is sponsored' do
          let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: 'TIERED', covers_dpc: true, covers_ldf: false) }
          let(:resource_file_size) { 153_200_000_000 }

          it 'user pays nothing and no LDF log created' do
            sponsored_no_fee
            no_ldf
          end
        end
      end
    end
  end
end

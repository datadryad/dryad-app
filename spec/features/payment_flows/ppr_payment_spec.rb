RSpec.feature 'PPR PaymentFlows', type: :feature, js: true do
  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Aws
  include Mocks::DataFile
  include Mocks::Stripe

  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  before do
    mock_solr_frontend!
    mock_aws!
    mock_file_content!
    mock_stripe!

    sign_in(user)
    start_new_dataset
  end

  context 'on first version' do
    before { build_full_dataset }

    it 'payment is not sponsored' do
      expect(page).not_to have_text('Payment for this submission is sponsored by')
    end

    context 'payment value' do
      it 'user pays DPC' do
        expect(page).to have_content('dataset has a Data Publishing Charge of $150.00')
        expect(page).not_to have_content('Payment for this submission is sponsored by')
        expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
      end

      context 'when is set to PPR' do
        before do
          click_button 'Agreements'
          find('label', text: 'Keep my files private while my manuscript undergoes peer review').click
          click_button 'Preview changes'
        end

        it 'user is informed he can pay only the PPR fee' do
          expect(page).not_to have_content('Payment for this submission is sponsored by')
          expect(page).to have_content('dataset has a Data Publishing Charge of $150.00')
          expect(page).to have_content('You may choose to pay only $50.00, with the remainder due at the end of the peer review period. The Private for Peer Review Fee is nonrefundable.')

          expect(page).to have_css('button', exact_text: 'Pay & Submit for peer review')
        end

        context 'when on payment page' do
          it 'user can choose between full fee and PPR fee' do
            click_button 'Pay & Submit for peer review'

            expect(page).to have_content('dataset has a Data Publishing Charge of $150.00')
            expect(page).to have_content('You may choose to pay only $50.00, with the remainder due at the end of the peer review period. The Private for Peer Review Fee is nonrefundable.')

            expect(page).to have_css('button', exact_text: 'Pay full $150.00 now')
            expect(page).to have_css('button', exact_text: 'Pay $50.00 Peer Review Fee')
          end
        end

        context 'when LDF exists' do
          before do
            upload_file(size: '54_000_000_000', file_name: 'ldf.txt')
            click_button 'Preview changes'
          end

          it 'user is informed he can pay only the PPR fee' do
            expect(page).not_to have_content('Payment for this submission is sponsored by')
            expect(page).to have_content('This 54 GB dataset has a Data Publishing Charge of $808.00')
            expect(page).to have_content('You may choose to pay only $50.00, with the remainder due at the end of the peer review period. The Private for Peer Review Fee is nonrefundable.')

            expect(page).to have_css('button', exact_text: 'Pay & Submit for peer review')
          end

          context 'when on payment page' do
            it 'user can choose between full fee and PPR fee' do
              click_button 'Pay & Submit for peer review'

              expect(page).to have_content('This 54 GB dataset has a Data Publishing Charge of $808.00')
              expect(page).to have_content('You may choose to pay only $50.00, with the remainder due at the end of the peer review period. The Private for Peer Review Fee is nonrefundable.')

              expect(page).to have_css('button', exact_text: 'Pay full $808.00 now')
              expect(page).to have_css('button', exact_text: 'Pay $50.00 Peer Review Fee')
            end
          end
        end
      end
    end
  end

  describe 'on second version' do
    let(:last_invoiced_file_size) { 34 }
    let(:resource_file_size) { 10 }
    let!(:identifier) do
      create(:identifier, last_invoiced_file_size: last_invoiced_file_size, license_id: :cc0)
    end
    let(:resource) do
      create(:resource, identifier: identifier, user: user, accepted_agreement: true, hold_for_peer_review: true,
             created_at: 1.minute.ago, total_file_size: last_invoiced_file_size)
    end
    let!(:payment) do
      create(:resource_payment, resource: resource, amount: 150, payment_type: 'stripe', status: :paid)
    end

    before do
      create(:description, resource: resource, description_type: 'technicalinfo')
      create(:description, resource: resource, description_type: 'hsi_statement', description: nil)
      create(:description, resource: resource, description_type: 'abstract', description: 'Abstract')
      create(:data_file, resource: resource, download_filename: 'file1.txt', file_state: 'created', upload_file_size: 1000)
      create(:data_file, resource: resource, download_filename: 'README.md', file_state: 'created', upload_file_size: 100)

      CurationService.new(user: user, resource: resource, status: 'queued').process
      resource.current_state = :submitted

      click_link 'My datasets'
      click_button 'Revise submission'

      identifier.reload
      resource.reload
    end

    include_examples 'ppr - individual user does not pay anything'

    context 'payment value' do
      context 'when paid in fill' do
        context 'when nothing changes' do
          include_examples 'ppr - individual user does not pay anything'
          include_examples 'ppr - no LDF sponsored payment log is created'
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size, file_name: 'ldf.txt')
            click_button 'Preview changes'
          end

          context 'and tier is not exceeded' do
            include_examples 'ppr - individual user does not pay anything'
            include_examples 'ppr - no LDF sponsored payment log is created'
          end

          context 'and tier is exceeded' do
            let(:resource_file_size) { 20_000_000_000 }

            context 'when DPC was paid in full (not the PPR fee)' do
              include_examples 'ppr - individual user must pay', '20 GB', '370.00'
              include_examples 'ppr - no LDF sponsored payment log is created'

              it 'user is not prompted to pay the PPR fee' do
                expect(page).not_to have_content('You may choose to pay only $50.00, with the remainder due at the end of the peer review period. The Private for Peer Review Fee is nonrefundable.')
              end

              context 'when on payment page' do
                context 'when DPC was paid in full (not the PPR fee)' do
                  include_examples 'ppr - individual user must pay', '20 GB', '370.00'

                  it 'user can not choose PPR fee' do
                    click_button 'Pay & Submit for peer review'

                    expect(page).to have_content('Since the dataset size has increased to 20 GB, submitting this new version will come with an additional charge of $370.00.')
                    expect(page).not_to have_content('You may choose to pay only $50.00, with the remainder due at the end of the peer review period. The Private for Peer Review Fee is nonrefundable.')

                    expect(page).not_to have_css('button', exact_text: 'Pay full $150.00 now')
                    expect(page).not_to have_css('button', exact_text: 'Pay $50.00 Peer Review Fee')
                  end
                end
              end
            end

            context 'when only the ppr fee was paid' do
              let!(:payment) do
                create(:resource_payment, resource: resource, amount: 50, payment_type: 'stripe', status: :paid, ppr_fee_paid: true)
              end

              include_examples 'ppr - individual user does not pay anything'

              xit 'notifies the user that the PPR fee was already paid' do
                expect(page).to have_content('The $50.00 Private for Peer Review Fee has been paid. The remainder of the Data Publishing Charge is due at submission for curation and publication.')
              end
            end
          end
        end
      end
    end
  end
end

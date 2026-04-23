RSpec.feature 'Publisher sponsored PaymentFlows', type: :feature, js: true do
  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Aws
  include Mocks::DataFile
  include Mocks::Stripe

  let!(:top_level_sponsor) { create(:journal_organization, parent_org: nil) }
  let!(:sponsor_payment) do
    create(:payment_configuration, partner: top_level_sponsor, payment_plan: '2025', covers_dpc: true)
  end

  let!(:level_one_sponsor) { create(:journal_organization, parent_org: top_level_sponsor) }
  let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor) }

  let!(:journal) { create(:journal, sponsor: level_one_sponsor) }
  let(:user) { create(:user) }
  let(:paid_ldf) { 0 }
  let(:resource_file_size) { 10 }
  let(:payer_name) { journal.title }

  before do
    mock_solr_frontend!
    mock_aws!
    mock_file_content!
    mock_stripe!

    create(:sponsored_payment_log, payer: journal, sponsor_id: top_level_sponsor.id, ldf: paid_ldf)

    sign_in(user)
  end

  describe 'on first version' do
    before do
      start_new_dataset
      build_min_dataset(resource_file_size: resource_file_size)

      connect_journal(journal)
      click_button 'Preview changes'
    end

    it 'payment sponsored' do
      expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
    end

    context 'payment value' do
      it 'user does not pay DPC' do
        expect(page).not_to have_content('Data Publishing Charge')
        expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
        expect(page).to have_css('button', exact_text: 'Submit for publication')
      end

      context 'when LDF is not covered' do
        let(:resource_file_size) { 53_200_000_000 }

        it 'user pays LDF value' do
          expect(page).to have_content('This 53.2 GB dataset has a Large data fee of $464.00.')
          expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
          expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
        end
      end

      context 'when LDF is covered' do
        let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true) }
        let(:resource_file_size) { 53_200_000_000 }

        it 'sponsored user does not pay anything' do
          expect(page).not_to have_content('Large data fee')
          expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
          expect(page).to have_css('button', exact_text: 'Submit for publication')
        end

        context 'and limited by size' do
          let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true, ldf_limit: 2) }

          context 'dataset is under the limit' do
            let(:resource_file_size) { 13_200_000_000 }

            it 'sponsored user does not pay anything' do
              expect(page).not_to have_content('Large data fee')
              expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
              expect(page).to have_css('button', exact_text: 'Submit for publication')
            end
          end

          context 'dataset is over the limit' do
            let(:resource_file_size) { 123_200_000_000 }

            it 'user pays only the difference' do
              expect(page).to have_content('This 123.2 GB dataset has a Large data fee overage of $659.00')
              expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
              expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
            end
          end
        end

        context 'and limited by yearly amount' do
          let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true, yearly_ldf_limit: 1_000) }

          context 'dataset is under the limit' do
            let(:resource_file_size) { 53_200_000_000 }

            it 'sponsored user does not pay anything' do
              expect(page).not_to have_content('Large data fee')
              expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
              expect(page).to have_css('button', exact_text: 'Submit for publication')
            end
          end

          context 'dataset is over the limit' do
            let(:resource_file_size) { 123_200_000_000 }

            it 'user pays the entire amount' do
              expect(page).to have_content('This 123.2 GB dataset has a Large data fee of $1,123.00')
              expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
              expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
            end
          end
        end

        context 'and both size and yearly amount limits are set' do
          let!(:limits_payment) do
            create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true, ldf_limit: 1, yearly_ldf_limit: 1_000)
          end

          context 'dataset is under size the limit' do
            let(:resource_file_size) { 13_200_000_000 }

            context 'and amount limit will not be reached' do
              let(:paid_ldf) { 700 }

              it 'sponsored user does not pay anything' do
                expect(page).not_to have_content('Large data fee')
                expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
                expect(page).to have_css('button', exact_text: 'Submit for publication')
              end
            end

            context 'and amount limit is not reached but will be exceeded' do
              let(:paid_ldf) { 800 }

              it 'user pays for the entire amount' do
                expect(page).to have_content('This 13.2 GB dataset has a Large data fee overage of $259.00')
                expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
                expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
              end
            end

            context 'and amount limit is already exceeded' do
              let(:paid_ldf) { 1_001 }

              it 'user pays for the entire amount' do
                expect(page).to have_content('This 13.2 GB dataset has a Large data fee overage of $259.00')
                expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
                expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
              end
            end
          end

          context 'dataset is over the size limit' do
            let(:resource_file_size) { 51_200_000_000 }

            context 'and amount limit will not be reached' do
              let(:paid_ldf) { 100 }

              it 'user pays for the entire amount' do
                expect(page).to have_content('This 51.2 GB dataset has a Large data fee overage of $205.00')
                expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
                expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
              end
            end

            context 'and amount limit is not reached but will be exceeded' do
              let(:paid_ldf) { 800 }

              it 'user pays for the entire amount' do
                expect(page).to have_content('This 51.2 GB dataset has a Large data fee overage of $464.00')
                expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
                expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
              end
            end

            context 'and amount limit is already exceeded' do
              let(:paid_ldf) { 1_001 }

              it 'user pays for the entire amount' do
                expect(page).to have_content('This 51.2 GB dataset has a Large data fee overage of $464.00')
                expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
                expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
              end
            end
          end
        end
      end

      context 'when payer is not on 2025' do
        context 'all is sponsored' do
          let!(:sponsor_payment) do
            create(:payment_configuration, partner: top_level_sponsor, payment_plan: 'SUBSCRIPTION', covers_dpc: true)
          end
          let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: false) }
          let(:resource_file_size) { 151_200_000_000 }

          it 'sponsored user does not pay anything' do
            expect(page).not_to have_content('Large data fee')
            expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
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
      create(:identifier, payment_type: 'journal-2025', payment_id: journal&.single_issn,
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

      manuscript = create(:manuscript, identifier: resource.identifier, status: 'accepted', journal: journal)
      create(:resource_publication, resource: resource, manuscript_number: manuscript.manuscript_number, publication_issn: journal.single_issn)

      create(:data_file, resource: resource, download_filename: 'file1.txt', file_state: 'created', upload_file_size: 1000)
      create(:data_file, resource: resource, download_filename: 'README.md', file_state: 'created', upload_file_size: 100)

      CurationService.new(user: user, resource: resource, status: 'queued').process
      resource.current_state = :submitted

      click_link 'My datasets'
      click_button 'Revise submission'

      identifier.reload
      resource.reload
    end

    include_examples 'sponsored user does not pay anything'

    context 'payment value' do
      context 'ldf is not covered' do
        context 'when nothing changes' do
          include_examples 'sponsored user does not pay anything'
          include_examples 'no LDF sponsored payment log is created'
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview changes'
          end

          context 'and tier is not exceeded' do
            include_examples 'sponsored user does not pay anything'
            include_examples 'no LDF sponsored payment log is created'
          end

          context 'and tier is exceeded' do
            let(:resource_file_size) { 20_000_000_000 }

            include_examples 'sponsored user must pay', '20 GB', '259.00'
            include_examples 'no LDF sponsored payment log is created'
          end
        end
      end

      context 'ldf is covered but not limited' do
        let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true) }

        context 'when nothing changes' do
          include_examples 'sponsored user does not pay anything'
          include_examples 'no LDF sponsored payment log is created'
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview changes'
          end

          context 'and tier is not changed' do
            include_examples 'sponsored user does not pay anything'
            include_examples 'no LDF sponsored payment log is created'
          end

          context 'and tier is changed' do
            let(:resource_file_size) { 53_200_000_000 }

            include_examples 'sponsored user does not pay anything'
            include_examples 'logs sponsored LDF value', 464
          end
        end
      end

      context 'ldf is covered and limited by size' do
        let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true, ldf_limit: 2) }

        context 'when nothing changes' do
          include_examples 'sponsored user does not pay anything'
          include_examples 'no LDF sponsored payment log is created'
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview changes'
          end

          context 'when limit tier is not changed' do
            let(:last_invoiced_file_size) { 20_000_000_000 }
            let(:resource_file_size) { 44_200_000_000 }

            include_examples 'sponsored user does not pay anything'
            include_examples 'no LDF sponsored payment log is created'
          end

          context 'when limit tier is exceeded' do
            let(:resource_file_size) { 153_200_000_000 }

            include_examples 'sponsored user must pay', '153.2 GB', '659.00'
            include_examples 'logs sponsored LDF value', 464
          end

          context 'when limit tier is not exceeded, logs only the difference' do
            let(:last_invoiced_file_size) { 12_000_000_000 }
            let(:resource_file_size) { 55_000_000_000 }

            include_examples 'sponsored user does not pay anything'
            include_examples 'logs sponsored LDF value', 205
          end
        end
      end

      context 'ldf is covered and limited by yearly amount' do
        let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true, yearly_ldf_limit: 1_000) }

        context 'when nothing changes' do
          include_examples 'sponsored user does not pay anything'
          include_examples 'no LDF sponsored payment log is created'
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview changes'
          end

          context 'and LDF tier is not changed' do
            let(:last_invoiced_file_size) { 20_000_000_000 }
            let(:resource_file_size) { 44_200_000_000 }

            include_examples 'sponsored user does not pay anything'
            include_examples 'no LDF sponsored payment log is created'
          end

          context 'when yearly limit is exceeded' do
            let(:resource_file_size) { 153_200_000_000 }

            include_examples 'sponsored user must pay', '153.2 GB', '1,123.00'
            include_examples 'no LDF sponsored payment log is created'
          end

          context 'when LDF tier is exceeded, logs only the difference' do
            let(:last_invoiced_file_size) { 12_000_000_000 }
            let(:resource_file_size) { 55_000_000_000 }

            include_examples 'sponsored user does not pay anything'
            include_examples 'logs sponsored LDF value', 205
          end
        end
      end

      context 'ldf is covered and limited by size and yearly amount' do
        let!(:limits_payment) do
          create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true,
                                         ldf_limit: 2, yearly_ldf_limit: 1_000)
        end

        context 'when nothing changes' do
          include_examples 'sponsored user does not pay anything'
          include_examples 'no LDF sponsored payment log is created'
        end

        context 'when files are added' do
          before do
            upload_file(size: resource_file_size)
            click_button 'Preview changes'
          end

          context 'and LDF tier is not changed' do
            let(:last_invoiced_file_size) { 20_000_000_000 }
            let(:resource_file_size) { 44_200_000_000 }

            include_examples 'sponsored user does not pay anything'
            include_examples 'no LDF sponsored payment log is created'
          end

          context 'when LDF limit will be exceeded, but yearly limit not' do
            let(:last_invoiced_file_size) { 12_200_000_000 }
            let(:resource_file_size) { 153_200_000_000 }

            include_examples 'sponsored user must pay', '153.2 GB', '659.00'
            include_examples 'logs sponsored LDF value', 205
          end

          context 'when LDF limit is already exceeded, but yearly limit not' do
            let(:last_invoiced_file_size) { 53_200_000_000 }
            let(:resource_file_size) { 153_200_000_000 }

            include_examples 'sponsored user must pay', '153.2 GB', '659.00'
            include_examples 'no LDF sponsored payment log is created'
          end

          context 'when LDF limit is exceeded, and yearly limit is exceeded' do
            let(:last_invoiced_file_size) { 12_000_000_000 }
            let(:resource_file_size) { 153_200_000_000 }
            let!(:sponsored_payment_log) do
              create(:sponsored_payment_log, ldf: 900, resource_id: resource.id, payer: journal, sponsor_id: top_level_sponsor.id)
            end

            include_examples 'sponsored user must pay', '153.2 GB', '864.00'
            include_examples 'no LDF sponsored payment log is created'
          end
        end
      end

      context 'when payer is not on 2025' do
        before do
          upload_file(size: resource_file_size)
          click_button 'Preview changes'
        end

        context 'all is sponsored' do
          let!(:sponsor_payment) do
            create(:payment_configuration, partner: top_level_sponsor, payment_plan: 'SUBSCRIPTION', covers_dpc: true)
          end
          let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: false) }
          let(:resource_file_size) { 151_200_000_000 }

          include_examples 'sponsored user does not pay anything'
          include_examples 'no LDF sponsored payment log is created'
        end
      end
    end
  end
end

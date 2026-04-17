RSpec.feature 'Publisher sponsored PaymentFlows', type: :feature, js: true do
  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Aws

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

  before do
    mock_solr_frontend!
    mock_aws!

    create(:sponsored_payment_log, payer: journal, sponsor_id: top_level_sponsor.id, ldf: paid_ldf)

    sign_in(user)
    start_new_dataset
  end

  describe 'on first version' do
    before do
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

        it 'user does not pay anything' do
          expect(page).not_to have_content('Large data fee')
          expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
          expect(page).to have_css('button', exact_text: 'Submit for publication')
        end

        context 'and limited by size' do
          let!(:limits_payment) { create(:payment_configuration, partner: level_one_sponsor, covers_ldf: true, ldf_limit: 2) }

          context 'dataset is under the limit' do
            let(:resource_file_size) { 13_200_000_000 }

            it 'user does not pay anything' do
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

            it 'user does not pay anything' do
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

              it 'user does not pay anything' do
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

          context 'dataset is over size the limit' do
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
    end
  end
end

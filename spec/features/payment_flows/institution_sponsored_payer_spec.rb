RSpec.feature 'Institution sponsored PaymentFlows', type: :feature, js: true do
  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Aws

  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true) }

  before do
    mock_solr_frontend!
    mock_aws!

    sign_in(user)
    start_new_dataset
  end

  describe 'on first version' do
    it 'payment sponsored' do
      build_min_dataset

      expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
    end

    context 'payment value' do
      it 'user does not pay DPC' do
        build_min_dataset

        expect(page).not_to have_content('Data Publishing Charge')
        expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
        expect(page).to have_css('button', exact_text: 'Submit for publication')
      end

      context 'when LDF is not covered' do
        it 'user pays LDF value' do
          build_min_dataset(resource_file_size: '53_200_000_000')

          expect(page).to have_content('This 53.2 GB dataset has a Large data fee of $464.00.')
          expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
          expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
        end
      end

      context 'when LDF is covered' do
        let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: true) }

        it 'user does not pay anything' do
          build_min_dataset(resource_file_size: '53_200_000_000')

          expect(page).not_to have_content('Large data fee')
          expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
          expect(page).to have_css('button', exact_text: 'Submit for publication')
        end

        context 'and limited by size' do
          let!(:payment_conf) do
            create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true,
                                           covers_ldf: true, ldf_limit: 2)
          end

          context 'dataset is under the limit' do
            it 'user does not pay anything' do
              build_min_dataset(resource_file_size: '13_200_000_000')

              expect(page).not_to have_content('Large data fee')
              expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
              expect(page).to have_css('button', exact_text: 'Submit for publication')
            end
          end

          context 'dataset is over the limit' do
            it 'user pays only the difference' do
              build_min_dataset(resource_file_size: '123_200_000_000')

              expect(page).to have_content('This 123.2 GB dataset has a Large data fee overage of $659.00')
              expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
              expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
            end
          end
        end

        context 'and limited by yearly amount' do
          let!(:payment_conf) do
            create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true,
                                           covers_ldf: true, yearly_ldf_limit: 1_000)
          end

          context 'dataset is under the limit' do
            it 'user does not pay anything' do
              build_min_dataset(resource_file_size: '53_200_000_000')

              expect(page).not_to have_content('Large data fee')
              expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
              expect(page).to have_css('button', exact_text: 'Submit for publication')
            end
          end

          context 'dataset is over the limit' do
            it 'user pays the entire amount' do
              build_min_dataset(resource_file_size: '123_200_000_000')

              expect(page).to have_content('This 123.2 GB dataset has a Large data fee of $1,123.00')
              expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
              expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
            end
          end
        end
      end
    end
  end
end

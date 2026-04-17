RSpec.feature 'Individual user PaymentFlows', type: :feature, js: true do
  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Aws

  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  before do
    mock_solr_frontend!
    mock_aws!

    sign_in(user)
    start_new_dataset
  end

  context 'on first version' do
    it 'payment is not sponsored' do
      build_min_dataset

      expect(page).not_to have_text('Payment for this submission is sponsored by')
    end

    context 'payment value' do
      it 'user pays DPC' do
        build_min_dataset

        expect(page).to have_content('This 10 B dataset has a Data Publishing Charge of $150.00')
        expect(page).not_to have_content('Payment for this submission is sponsored by')
        expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
      end

      it 'user pays different based on files size' do
        build_min_dataset(resource_file_size: '53_200_000_000')

        expect(page).to have_content('This 53.2 GB dataset has a Data Publishing Charge of $808.00')
        expect(page).not_to have_content('Payment for this submission is sponsored by')
        expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
      end
    end
  end
end

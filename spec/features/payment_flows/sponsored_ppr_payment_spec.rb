RSpec.feature 'PPR PaymentFlows for sponsored user', type: :feature, js: true do
  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Aws
  include Mocks::DataFile
  include Mocks::Stripe

  let(:tenant) { create(:tenant) }
  let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: false) }
  let(:user) { create(:user, tenant: tenant) }
  let(:payer_name) { tenant.long_name }

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

    it 'payment is sponsored' do
      expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
    end

    context 'payment value' do
      it 'user does not pay DPC' do
        expect(page).to have_text("Payment for this submission is sponsored by #{tenant.long_name}")
        expect(page).not_to have_css('button', exact_text: 'Pay & Submit for publication')
        expect(page).to have_css('button', exact_text: 'Submit for publication')
      end

      context 'when is set to PPR' do
        before do
          click_button 'Agreements'
          find('label', text: 'Keep my files private while my manuscript undergoes peer review').click
          click_button 'Preview changes'
        end

        # it 'user does not pay anything, the PPR fee also is sponsored'
        include_examples 'ppr - sponsored user does not pay anything'

        context 'when LDF exists' do
          before do
            upload_file(size: '54_000_000_000', file_name: 'ldf.txt')
            click_button 'Preview changes'
          end

          # it 'user does not pay anything, the PPR fee also is sponsored'
          include_examples 'ppr - sponsored user does not pay anything'
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

    include_examples 'ppr - sponsored user does not pay anything'

    context 'payment value' do
      context 'when nothing changes' do
        include_examples 'ppr - sponsored user does not pay anything'
      end

      context 'when files are added' do
        before do
          upload_file(size: resource_file_size, file_name: 'ldf.txt')
          click_button 'Preview changes'
        end

        context 'and tier is not exceeded' do
          include_examples 'ppr - sponsored user does not pay anything'
        end

        context 'and tier is exceeded' do
          let(:resource_file_size) { 20_000_000_000 }

          include_examples 'ppr - sponsored user does not pay anything'
        end
      end
    end
  end
end

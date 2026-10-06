RSpec.feature 'Individual user PaymentFlows', type: :feature, js: true do
  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Aws
  include Mocks::DataFile
  include Mocks::Stripe

  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:resource_file_size) { 10 }

  before do
    mock_solr_frontend!
    mock_aws!
    mock_file_content!
    mock_stripe!

    sign_in(user)
    start_new_dataset
  end

  context 'on first version' do
    context 'payment value' do
      before do
        build_min_dataset(resource_file_size: resource_file_size)
        expect(page).to have_button('submit_button', wait: 25)
      end

      it 'user pays DPC' do
        expect(page).to have_content('This 10 B dataset has a Data Publishing Charge of $150.00')
        expect(page).not_to have_content('Payment for this submission is sponsored by')
      end

      context 'larger dataset' do
        let(:resource_file_size) { 53_200_000_000 }

        it 'user pays larger DPC based on file size' do
          expect(page).to have_content('This 53.2 GB dataset has a Data Publishing Charge of $808.00')
          expect(page).not_to have_content('Payment for this submission is sponsored by')
        end
      end
    end

    context 'when submitting' do
      before do
        build_full_dataset(resource_file_size: '53_200_000_000')
        expect(page).to have_button('submit_button', wait: 25)
      end

      let(:identifier) { StashEngine::Identifier.last }
      include_examples 'pays and no LDF sponsored payment log is created'
    end
  end

  describe 'on second version' do
    let(:last_invoiced_file_size) { 34 }
    let(:resource_file_size) { 10 }
    let!(:identifier) do
      create(:identifier, last_invoiced_file_size: last_invoiced_file_size, license_id: :cc0)
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
    end

    include_examples 'individual user does not pay anything'

    context 'payment value' do
      context 'when nothing changes' do
        include_examples 'individual user does not pay anything'
        include_examples 'no LDF sponsored payment log is created'
      end

      context 'when files are added' do
        before do
          upload_file(size: resource_file_size)
          click_button 'Preview changes'
        end

        context 'and tier is not exceeded' do
          include_examples 'individual user does not pay anything'
          include_examples 'no LDF sponsored payment log is created'
        end

        context 'and tier is exceeded' do
          let(:resource_file_size) { 20_000_000_000 }

          include_examples 'individual user must pay', '20 GB', '370.00'
          include_examples 'pays and no LDF sponsored payment log is created'
        end
      end
    end
  end
end

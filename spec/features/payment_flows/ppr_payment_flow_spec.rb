RSpec.feature 'PPR PaymentFlows', type: :feature, js: true do
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

  #   describe 'on first version' do
  #     before do
  #       start_new_dataset
  #       build_full_dataset(resource_file_size: resource_file_size)
  #
  #       click_button 'Agreements'
  #       find('label', text: 'Keep my files private while my manuscript undergoes peer review').click
  #       click_button 'Preview changes'
  #
  #       connect_journal(journal)
  #       click_button 'Preview changes'
  #     end
  #
  #     it 'payment sponsored' do
  #       expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
  #     end
  #
  #     context 'payment value' do
  #       include_examples 'user does not pay anything'
  #
  #       context 'when LDF is not covered' do
  #         let(:resource_file_size) { 53_200_000_000 }
  #
  #         it 'user pays LDF value' do
  #           expect(page).to have_content('This 53.2 GB dataset has a Large data fee of $464.00.')
  #           expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
  #           expect(page).to have_css('button', exact_text: 'Pay & Submit for peer review')
  #
  #           click_button 'Pay & Submit for peer review'
  #           binding.pry
  #         end
  #       end
  #     end
  #   end
  #
  #   context 'on second version' do
  #     let(:last_invoiced_file_size) { 34 }
  #     let(:resource_file_size) { 10 }
  #     let!(:identifier) do
  #       create(:identifier, payment_type: 'journal-2025', payment_id: journal&.single_issn,
  #              last_invoiced_file_size: last_invoiced_file_size, license_id: :cc0)
  #     end
  #     let(:resource) do
  #       create(:resource, identifier: identifier, user: user, accepted_agreement: true, hold_for_peer_review: true,
  #              created_at: 1.minute.ago, total_file_size: last_invoiced_file_size)
  #     end
  #
  #     before do
  #       create(:description, resource: resource, description_type: 'technicalinfo')
  #       create(:description, resource: resource, description_type: 'hsi_statement', description: nil)
  #       create(:description, resource: resource, description_type: 'abstract', description: 'Abstract')
  #
  #       manuscript = create(:manuscript, identifier: resource.identifier, status: 'accepted', journal: journal)
  #       create(:resource_publication, resource: resource, manuscript_number: manuscript.manuscript_number, publication_issn: journal.single_issn)
  #
  #       create(:data_file, resource: resource, download_filename: 'file1.txt', file_state: 'created', upload_file_size: 1000)
  #       create(:data_file, resource: resource, download_filename: 'README.md', file_state: 'created', upload_file_size: 100)
  #
  #       CurationService.new(user: user, resource: resource, status: 'peer_review').process
  #       resource.current_state = :submitted
  #
  #       click_link 'My datasets'
  #       click_button 'Revise submission'
  #
  #       identifier.reload
  #       resource.reload
  #     end
  #
  #     context 'when nothing changes' do
  #       include_examples 'user does not pay anything'
  #       include_examples 'no LDF sponsored payment log is created'
  #     end
  #
  #     context 'when user should pay LDF and also sponsored log should be created' do
  #       let(:last_invoiced_file_size) { 12_200_000_000 }
  #       let(:resource_file_size) { 153_200_000_000 }
  #
  #       include_examples 'user does not pay anything'
  #       include_examples 'no LDF sponsored payment log is created'
  #     end
  #   end
end

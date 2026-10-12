RSpec.describe 'PaymentsController', type: :request do
  let!(:publisher) { create(:journal_organization, parent_org: nil) }
  let!(:journal) { create(:journal, sponsor: publisher) }

  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier, total_file_size: 100) }
  let!(:resource_publication) { create(:resource_publication, publication_issn: journal.single_issn, resource: resource) }
  let!(:payment_record) { create(:payment_record, resource: resource, identifier: identifier, payment: journal, payment_plan: '2025') }

  let(:session_id) { '12345' }
  let!(:payment) { create(:resource_payment, resource: resource, checkout_session_id: session_id, status: :created) }
  let!(:stripe_response) { OpenStruct.new(payment_intent: 'pi_12345', payment_status: 'paid', customer_email: 'test@test.com') }

  before do
    allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(stripe_response)
  end

  describe '#callback' do
    subject { get callback_payments_url, params: { session_id: session_id, resource_id: resource.id } }

    describe '#update_payment_details' do
      context 'when the user needs to pay' do
        context 'when dataset is sponsored' do
          let!(:payment_config) { create(:payment_configuration, partner: publisher, payment_plan: '2025', covers_dpc: true) }

          it 'does not overwrite identifier payment fields' do
            subject

            expect(identifier.reload.dpc_payment.payment).to eq(journal)
          end
        end

        context 'when dataset is not a sponsor anymore' do
          let!(:payment_config) { create(:payment_configuration, partner: publisher, payment_plan: nil, covers_dpc: false) }

          it 'overwrites identifier payment fields with stripe payment' do
            subject

            expect(identifier.reload.dpc_payment.payment).not_to eq(journal)
            expect(identifier.dpc_payment.payment.payment_id).to eq(stripe_response.payment_intent)
          end
        end

        context 'when dataset is not sponsored' do
          let(:identifier) { create(:identifier) }
          let!(:resource_publication) { nil }
          let!(:payment_record) { nil }

          it 'overwrites identifier payment fields' do
            subject

            expect(identifier.dpc_payment.payment.payment_id).to eq(stripe_response.payment_intent)
          end
        end
      end
    end
  end
end

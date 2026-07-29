RSpec.describe 'PaymentsController', type: :request do
  let!(:publisher) { create(:journal_organization, parent_org: nil) }
  let!(:journal) { create(:journal, sponsor: publisher) }

  let(:identifier) { create(:identifier, payment_type: 'journal-2025', payment_id: journal.single_issn) }
  let(:resource) { create(:resource, identifier: identifier, total_file_size: 100) }
  let!(:resource_publication) { create(:resource_publication, publication_issn: journal.single_issn, resource: resource) }

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

            expect(identifier.reload.payment_type).to eq('journal-2025')
            expect(identifier.payment_id).to eq(journal.single_issn)
          end
        end

        context 'when dataset is not a sponsor anymore' do
          it 'overwrites identifier payment fields with stripe payment' do
            subject

            expect(identifier.reload.payment_type).to eq('stripe')
            expect(identifier.payment_id).to eq(stripe_response.payment_intent)
          end
        end

        context 'when dataset is not sponsored' do
          let(:identifier) { create(:identifier, payment_type: 'stripe', payment_id: 'initial_payment') }
          let!(:resource_publication) { nil }

          it 'overwrites identifier payment fields' do
            subject

            expect(identifier.reload.payment_type).to eq('stripe')
            expect(identifier.payment_id).to eq(stripe_response.payment_intent)
          end
        end
      end
    end
  end
end

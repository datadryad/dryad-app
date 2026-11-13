RSpec.describe 'PaymentsController', type: :request do
  let!(:publisher) { create(:journal_organization, parent_org: nil) }
  let!(:journal) { create(:journal, sponsor: publisher) }

  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier, total_file_size: 100) }
  let!(:resource_publication) { create(:resource_publication, publication_issn: journal.single_issn, resource: resource) }
  let!(:payment_record) { create(:payment_record, resource: resource, identifier: identifier, payment: journal, payment_plan: '2025') }

  let(:session_id) { '12345' }
  let!(:payment) { create(:resource_payment, resource: resource, checkout_session_id: session_id, status: :created) }
  let!(:stripe_response) do
    OpenStruct.new(payment_intent: 'pi_12345', payment_status: stripe_status, customer_email: 'test@test.com', return_url: return_url)
  end
  let(:return_url) { "/payments/callback?resource_id=#{resource.id}&session_id={CHECKOUT_SESSION_ID}" }
  let(:stripe_status) { 'paid' }

  before do
    allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(stripe_response)
  end

  describe '#callback' do
    subject { get callback_payments_url, params: { session_id: session_id, resource_id: resource.id } }

    context 'when payment succeeds' do
      context 'when session_id matched payment' do
        it 'does not log anything and calls payment handler' do
          expect(Rails.logger).not_to receive(:warn)
          expect(Stripe::HandlePaymentsService).to receive_message_chain(:new, :mark_session_paid).with(payment).with(session_id)

          subject
        end
      end

      context 'when session_id does not match payment' do
        let!(:payment) { create(:resource_payment, resource: resource, checkout_session_id: 'aaa', status: :created) }

        it 'log a message and calls payment handler' do
          expect(Rails.logger).to receive(:warn).with("Resource #{resource.id} received a payment for wrong checkout session #{session_id}")
          expect(Stripe::HandlePaymentsService).to receive_message_chain(:new, :mark_session_paid).with(payment).with(session_id)

          subject
        end
      end
    end

    context 'when payment has wrong return url' do
      let(:return_url) { "/payments/callback?resource_id=#{resource.id + 100}&session_id={CHECKOUT_SESSION_ID}" }

      it 'log anything and calls payment handler' do
        expect(Rails.logger).to receive(:warn).with(
          "Resource #{resource.id} received a payment with incorrect information callback checkout session #{session_id}"
        )
        subject
        expect(flash[:alert]).to include('Payment has incorrect information, Please contact us at')
        expect(response).to redirect_to("/submission/#{resource.id}")
      end
    end

    context 'when payment has other status than paid' do
      let(:stripe_status) { 'failed' }

      it ' log anything and calls payment handler' do
        expect(Rails.logger).to receive(:warn).with(
          "Resource #{resource.id} received a payment with status #{stripe_status} for session #{session_id}"
        )
        subject
        expect(flash[:alert]).to include('Payment was not completed.')
        expect(response).to redirect_to("/submission/#{resource.id}")
      end
    end

    context 'when Stripe session retrieval fails' do
      before do
        allow(Stripe::Checkout::Session).to receive(:retrieve).and_raise(Stripe::StripeError, 'Test Stripe Error')
      end

      it 'redirects with an alert message' do
        expect(Rails.logger).to receive(:warn).with(
          "Stripe session retrieval error for resource #{resource.id} and session #{session_id}: Test Stripe Error"
        )
        subject
        expect(flash[:alert]).to include('Failed to verify Stripe session.')
        expect(response).to redirect_to("/submission/#{resource.id}")
      end
    end

    describe 'update_payment_details' do
      context 'when the user needs to pay' do
        context 'when dataset is sponsored' do
          let!(:payment_config) { create(:payment_configuration, partner: publisher, payment_plan: '2025') }

          it 'does not overwrite identifier payment fields' do
            subject

            expect(identifier.reload.dpc_payment.payment).to eq(journal)
          end
        end

        context 'when dataset is not sponsored anymore' do
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

            expect(identifier.payment_records.dpc.last.payment.payment_id).to eq(stripe_response.payment_intent)
          end
        end
      end
    end
  end
end

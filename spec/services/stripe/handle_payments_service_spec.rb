require 'rails_helper'

RSpec.describe Stripe::HandlePaymentsService do
  let!(:publisher) { create(:journal_organization, parent_org: nil) }
  let!(:journal) { create(:journal, sponsor: publisher) }

  let(:identifier) { create(:identifier, payment_type: 'journal-2025', payment_id: journal.single_issn) }
  let(:resource) { create(:resource, identifier: identifier, total_file_size: 100) }
  let!(:resource_publication) { create(:resource_publication, publication_issn: journal.single_issn, resource: resource) }

  let(:session_id) { '12345' }
  let(:payment_time) { Time.at(1_700_000_000) }
  let!(:payment) { create(:resource_payment, resource: resource, checkout_session_id: session_id, status: :created) }
  let!(:stripe_response) { OpenStruct.new(payment_intent: 'pi_12345', payment_status: 'paid', customer_email: 'test@test.com') }

  subject(:subject) { described_class.new(payment) }

  before do
    allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(stripe_response)
  end

  describe '#mark_session_paid' do
    context 'when the user needs to pay' do
      context 'when dataset is sponsored' do
        let!(:payment_config) { create(:payment_configuration, partner: publisher, payment_plan: '2025', covers_dpc: true) }

        it 'does not overwrite identifier payment fields' do
          subject.mark_session_paid(session_id)

          expect(identifier.reload.payment_type).to eq('journal-2025')
          expect(identifier.payment_id).to eq(journal.single_issn)
        end
      end

      context 'when dataset is not sponsored anymore' do
        it 'overwrites identifier payment fields with stripe payment' do
          subject.mark_session_paid(session_id)

          expect(identifier.reload.payment_type).to eq('stripe')
          expect(identifier.payment_id).to eq(stripe_response.payment_intent)
        end
      end

      context 'when dataset is not sponsored' do
        let(:identifier) { create(:identifier, payment_type: 'stripe', payment_id: 'initial_payment') }
        let!(:resource_publication) { nil }

        it 'overwrites identifier payment fields' do
          subject.mark_session_paid(session_id)

          expect(identifier.reload.payment_type).to eq('stripe')
          expect(identifier.payment_id).to eq(stripe_response.payment_intent)
        end
      end

      it 'updates payment record info' do
        subject.mark_session_paid(session_id, paid_at: payment_time)
        payment.reload

        expect(payment.payment_checkout_session_id).to eq(session_id)
        expect(payment.status).to eq('paid')
        expect(payment.paid_at).to eq(payment_time)
        expect(payment.status_time).to eq(payment_time)
        expect(payment.payment_intent).to eq('pi_12345')
        expect(payment.payment_status).to eq('paid')
        expect(payment.payment_email).to eq('test@test.com')
      end

      it 'updates identifier last_invoiced_file_size' do
        expect { subject.mark_session_paid(session_id, paid_at: payment_time) }.not_to(change { identifier.last_invoiced_file_size })

        expect(identifier.reload.last_invoiced_file_size).to eq(100)
      end
    end
  end
end

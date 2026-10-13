require 'rails_helper'

RSpec.describe Stripe::Handlers::CheckoutSessionCompleted do
  subject(:subject) { described_class.new(event: event) }

  let(:session_id) { 'cs_123' }
  let(:payment_intent) { 'pi_123' }
  let!(:payment) { create(:resource_payment, pay_with_invoice: false, checkout_session_id: session_id, status: 'created') }
  let(:event) do
    instance_double(
      Stripe::Event,
      to_h: { 'id' => 'evt_123' },
      data: instance_double(
        Stripe::Event::Data,
        object: session
      )
    )
  end

  let(:session) do
    instance_double(
      Stripe::Checkout::Session,
      id: session_id,
      payment_intent: payment_intent,
      created: 1_700_000_000
    )
  end

  describe '#initialize' do
    it 'stores the event as a hash' do
      expect(subject.event).to eq(event)
    end

    it 'stores the payment intent' do
      expect(subject.session_id).to eq(session_id)
    end

    it 'looks up the payment by payment_intent' do
      expect(subject.payment).to eq(payment)
    end
  end

  describe '#call' do
    context 'when a payment exists' do
      it 'calls proper service' do
        expect(Stripe::HandlePaymentsService).to receive_message_chain(:new, :mark_session_paid).with(payment).with(session_id,
                                                                                                                    paid_at: Time.at(1_700_000_000))

        subject.call
      end

      it 'marks the payment as paid' do
        subject.call
        expect(payment.reload.status).to eq('paid')
        expect(payment.payment_checkout_session_id).to eq(session_id)
        expect(payment.paid_at).to eq(Time.at(1_700_000_000))
        expect(payment.status_time).to eq(Time.at(1_700_000_000))
      end
    end

    context 'when no payment exists' do
      let!(:payment) { nil }

      it 'does not update a payment' do
        expect(Stripe::HandlePaymentsService).not_to receive(:new)
        expect(ResourcePayment).not_to receive(:update)

        subject.call
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with('Stripe - checkout.session.completed - No payment record for session_id cs_123.')

        subject.call
      end

      it 'returns nil' do
        expect(subject.call).to be_nil
      end
    end
  end

  describe '#status_time' do
    context 'when object has a created timestamp' do
      it 'returns the creation time' do
        expect(subject.send(:status_time)).to eq(Time.at(1_700_000_000))
      end
    end

    context 'when the object timestamp cannot be read' do
      before do
        allow(session).to receive(:created).and_raise(StandardError)
      end

      it 'returns the current time' do
        current_time = Time.zone.parse('2026-01-01 12:00:00')
        allow(Time).to receive(:current).and_return(current_time)

        expect(subject.send(:status_time)).to eq(current_time)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('Stripe - checkout.session.completed - Could not get status_time for session_id cs_123.')

        subject.send(:status_time)
      end
    end
  end
end

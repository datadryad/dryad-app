require 'rails_helper'

RSpec.describe Stripe::Handlers::ChargeRefunded do
  subject(:subject) { described_class.new(event: event) }

  let(:payment_intent) { 'pi_123' }
  let!(:payment) { create(:resource_payment, pay_with_invoice: false, payment_intent: payment_intent, status: 'paid') }
  let(:event) do
    instance_double(
      Stripe::Event,
      to_h: { 'id' => 'evt_123' },
      data: instance_double(
        Stripe::Event::Data,
        object: charge
      )
    )
  end

  let(:charge) do
    instance_double(
      Stripe::Charge,
      payment_intent: payment_intent,
      refunds: refunds
    )
  end

  let(:refunds) do
    double(
      data: [refund]
    )
  end

  let(:refund) do
    instance_double(
      Stripe::Refund,
      created: 1_700_000_000
    )
  end

  describe '#initialize' do
    it 'stores the event as a hash' do
      expect(subject.event).to eq(event)
    end

    it 'stores the payment intent' do
      expect(subject.payment_intent).to eq(payment_intent)
    end

    it 'looks up the payment by payment_intent' do
      expect(subject.payment).to eq(payment)
    end
  end

  describe '#call' do
    context 'when a payment exists' do
      it 'marks the payment as refunded' do
        subject.call
        expect(payment.reload.status).to eq('refunded')
        expect(payment.status_time).to eq(Time.at(1_700_000_000))
      end
    end

    context 'when no payment exists' do
      let!(:payment) { nil }

      it 'does not update a payment' do
        expect(ResourcePayment).not_to receive(:update)

        subject.call
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with('Stripe - charge.refunded - No payment record for payment_intent pi_123.')

        subject.call
      end

      it 'returns nil' do
        expect(subject.call).to be_nil
      end
    end
  end

  describe '#status_time' do
    context 'when the refund has a created timestamp' do
      it 'returns the refund creation time' do
        expect(subject.send(:status_time)).to eq(Time.at(1_700_000_000))
      end
    end

    context 'when the refund timestamp cannot be read' do
      before do
        allow(refunds).to receive(:data).and_raise(StandardError)
      end

      it 'returns the current time' do
        current_time = Time.zone.parse('2026-01-01 12:00:00')
        allow(Time).to receive(:current).and_return(current_time)

        expect(subject.send(:status_time)).to eq(current_time)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('Stripe - charge.refunded - Could not get status_time for payment_intent pi_123.')

        subject.send(:status_time)
      end
    end
  end
end

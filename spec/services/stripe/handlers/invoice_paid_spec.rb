require 'rails_helper'

RSpec.describe Stripe::Handlers::InvoicePaid do
  subject(:subject) { described_class.new(event) }

  let(:invoice_id) { 'in_123' }
  let(:resource) { create(:resource) }
  let!(:payment) { create(:resource_payment, pay_with_invoice: true, invoice_id: invoice_id, status: 'created', resource: resource) }
  let(:event) do
    instance_double(
      Stripe::Event,
      to_h: { 'id' => 'evt_123' },
      data: instance_double(
        Stripe::Event::Data,
        object: invoice
      )
    )
  end

  let(:invoice) do
    instance_double(
      Stripe::Invoice,
      id: invoice_id,
      status_transitions: status_transitions
    )
  end

  let(:status_transitions) do
    instance_double(Stripe::Invoice::StatusTransitions, paid_at: 1_700_000_000)
  end

  describe '#initialize' do
    it 'stores the event as a hash' do
      expect(subject.event).to eq(event)
    end

    it 'stores the invoice_id' do
      expect(subject.invoice_id).to eq(invoice_id)
    end

    it 'looks up the payment by invoice_id' do
      expect(subject.payment).to eq(payment)
    end
  end

  describe '#call' do
    context 'when a payment exists' do
      before { subject.call }

      it 'marks the payment as paid' do
        expect(payment.reload.status).to eq('paid')
        expect(payment.paid_at).to eq(Time.at(1_700_000_000))
        expect(payment.status_time).to eq(Time.at(1_700_000_000))
      end

      it 'creates a curation log' do
        expect(resource.reload.curation_activities.where(note: 'Invoice has been paid')).to exist
      end
    end

    context 'when no payment exists' do
      let!(:payment) { nil }

      it 'does not update a payment' do
        expect(ResourcePayment).not_to receive(:update)

        subject.call
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with('Stripe - invoice.paid - No payment record for Invoice with ID in_123.')

        subject.call
      end

      it 'returns nil' do
        expect(subject.call).to be_nil
      end
    end

    context 'when payment is already paid' do
      let!(:payment) { create(:resource_payment, pay_with_invoice: true, invoice_id: invoice_id, status: 'paid') }

      it 'does not update a payment' do
        expect(ResourcePayment).not_to receive(:update)

        subject.call
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with('Stripe - invoice.paid - Payment record is already marked as paid for Invoice with ID in_123.')

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
        allow(status_transitions).to receive(:paid_at).and_raise(StandardError)
      end

      it 'returns the current time' do
        current_time = Time.zone.parse('2026-01-01 12:00:00')
        allow(Time).to receive(:current).and_return(current_time)

        expect(subject.send(:status_time)).to eq(current_time)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('Stripe - invoice.paid - Could not get status_time for Invoice with ID in_123.')

        subject.send(:status_time)
      end
    end
  end
end

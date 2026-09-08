require 'rails_helper'

RSpec.describe Stripe::Handlers::InvoiceVoided do
  subject(:subject) { described_class.new(event: event) }

  let(:invoice_id) { 'in_123' }
  let(:latest_revision) { nil }
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
      latest_revision: latest_revision,
      status_transitions: status_transitions
    )
  end

  let(:status_transitions) do
    instance_double(Stripe::Invoice::StatusTransitions, voided_at: 1_700_000_000)
  end

  describe 'with an event' do
    describe '#initialize' do
      it 'stores the event as a hash' do
        expect(subject.event).to eq(event)
      end

      it 'stores the invoice' do
        expect(subject.invoice).to eq(invoice)
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
        it 'marks the payment as paid' do
          subject.call

          expect(payment.reload.status).to eq('voided')
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
          expect(Rails.logger).to receive(:warn).with('Stripe - invoice.voided - No payment record for Invoice with ID in_123.')

          subject.call
        end

        it 'returns nil' do
          expect(subject.call).to be_nil
        end
      end

      context 'when there is a newer revision' do
        let(:latest_revision) { 'in_456' }
        let(:latest_revision_2) { 'in_789' }
        let(:revision_1) do
          instance_double(
            Stripe::Invoice,
            id: invoice_id,
            latest_revision: latest_revision_2,
            status: 'void',
            status_transitions: status_transitions
          )
        end

        let(:revision_2) do
          instance_double(
            Stripe::Invoice,
            id: invoice_id,
            latest_revision: nil,
            status: 'void',
            status_transitions: status_transitions
          )
        end

        before do
          allow(Stripe::Invoice).to receive(:retrieve).with(latest_revision).and_return(revision_1)
          allow(Stripe::Invoice).to receive(:retrieve).with(latest_revision_2).and_return(revision_2)
        end

        it 'updates the payment just once' do
          expect_any_instance_of(ResourcePayment).to receive(:update).with(
            { invoice_id: 'in_789', status: :voided, status_time: Time.at(1_700_000_000), paid_at: nil }
          )

          subject.call
        end

        it 'returns nil' do
          expect(subject.call).to be_nil
        end
      end
    end
  end

  describe 'with an invoice' do
    subject(:subject) { described_class.new(invoice: invoice) }

    describe '#initialize' do
      it 'stores the event as nil' do
        expect(subject.event).to be_nil
      end

      it 'stores the invoice' do
        expect(subject.invoice).to eq(invoice)
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
        it 'marks the payment as paid' do
          subject.call

          expect(payment.reload.status).to eq('voided')
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
          expect(Rails.logger).to receive(:warn).with('Stripe - invoice.voided - No payment record for Invoice with ID in_123.')

          subject.call
        end

        it 'returns nil' do
          expect(subject.call).to be_nil
        end
      end
    end
  end

  describe '#voided_time' do
    context 'when the refund has a created timestamp' do
      it 'returns the refund creation time' do
        expect(subject.send(:voided_at, invoice)).to eq(Time.at(1_700_000_000))
      end
    end

    context 'when the refund timestamp cannot be read' do
      before do
        allow(status_transitions).to receive(:voided_at).and_raise(StandardError)
      end

      it 'returns the current time' do
        current_time = Time.zone.parse('2026-01-01 12:00:00')
        allow(Time).to receive(:current).and_return(current_time)

        expect(subject.send(:voided_at, invoice)).to eq(current_time)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('Stripe - invoice.voided - Could not get status_time for Invoice with ID in_123.')

        subject.send(:voided_at, invoice)
      end
    end
  end
end

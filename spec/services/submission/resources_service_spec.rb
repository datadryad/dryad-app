# spec/services/submission/resources_service_spec.rb
require 'rails_helper'

RSpec.describe Submission::ResourcesService do
  include Mocks::Stripe

  let(:user) { create(:user) }
  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier) }
  let(:author) { resource.owner_author }
  let(:resource_id) { resource.id }
  let!(:repo_queue_state) { create(:repo_queue_state, resource: resource, state: 'enqueued') }
  let(:service) { described_class.new(resource_id) }

  describe '#initialize' do
    subject { service }

    it 'sets proper attributes' do
      expect(subject.resource).to eq(resource)
      expect(subject.resource_id).to eq(resource_id)
    end
  end

  describe '#trigger_submission' do
    subject { service.trigger_submission }

    it 'updates resource current_state' do
      expect { subject }.to change { resource.reload.current_state }.to('processing')
    end

    it 'enqueues submission job' do
      expect { subject }.to change { Submission::SubmissionJob.jobs.size }.by(1)
    end

    it 'does not enqueue submission job multiple times' do
      expect { subject }.to change { Submission::SubmissionJob.jobs.size }.by(1)
      expect { subject }.to change { Submission::SubmissionJob.jobs.size }.by(0)
      expect { subject }.to change { Submission::SubmissionJob.jobs.size }.by(0)
    end
  end

  describe '#submit' do
    subject { service.submit }

    it 'updates queue status' do
      expect { subject }.to change {
        StashEngine::RepoQueueState.latest(resource_id: resource_id).state
      }.from('enqueued').to('processing')
    end

    it 'calls invoice creation' do
      expect(service).to receive(:handle_invoice_creation)
      subject
    end

    context 'with new files' do
      let!(:file1) { create(:data_file, resource: resource, file_state: 'created') }
      let!(:file2) { create(:data_file, resource: resource, file_state: 'created') }
      let!(:file3) { create(:data_file, resource: resource, file_state: 'copied') }

      it 'enqueues CopyFileJob job for each new file' do
        expect { subject }.to change { Submission::CopyFileJob.jobs.size }.by(2)
      end
    end

    context 'with no new files' do
      let!(:file) { create(:data_file, resource: resource, file_state: 'copied') }

      it 'enqueues submission CheckStatusJob' do
        expect { subject }.to change { Submission::CheckStatusJob.jobs.size }.by(1)
      end
    end
  end

  describe '#handle_invoice_creation' do
    subject { service.send(:handle_invoice_creation) }

    context 'with old payment system' do
      let(:identifier) { create(:identifier, old_payment_system: true) }

      it 'does not create any invoice' do
        expect(Stash::Payments::StripeInvoicer).not_to receive(:new)
        expect(subject).to be_nil
      end
    end

    context 'with new payment system' do
      context 'without a ResourcePayment record' do
        it 'does not create any invoice' do
          expect(Rails.logger).to receive(:warn).with("No payment found for resource ID #{resource.id}")
          expect(Stash::Payments::StripeInvoicer).not_to receive(:new)
          expect(subject).to be_nil
        end
      end

      context 'with ResourcePayment record set not to pay_with_invoice' do
        let!(:payment) { create(:resource_payment, resource: resource, pay_with_invoice: false) }

        it 'does not create any invoice' do
          expect(Rails.logger).to receive(:warn).with("Payment for resource ID #{resource.id} is not set to invoice")
          expect(Stash::Payments::StripeInvoicer).not_to receive(:new)
          expect(subject).to be_nil
        end
      end

      context 'with ResourcePayment record set to pay_with_invoice' do
        let(:invoice_id) { nil }
        let!(:payment) do
          create(
            :resource_payment,
            resource: resource,
            pay_with_invoice: true,
            invoice_id: invoice_id,
            invoice_details: {
              'author_id' => author.id,
              'customer_name' => 'Customer Name',
              'customer_email' => 'customer.email@example.com'
            }
          )
        end

        before do
          mock_stripe!
        end

        context 'when invoice_id is not set' do
          let(:invoice_id) { nil }

          it 'creates a new invoice' do
            subject
            expect(payment.reload.invoice_id).not_to be_nil
          end
        end

        context 'when invoice already exists' do
          let(:invoice_id) { 'some-id' }

          it 'returns nil' do
            expect do
              subject
            end.not_to(change do
              payment.reload.invoice_id
            end)
          end
        end
      end
    end
  end
end

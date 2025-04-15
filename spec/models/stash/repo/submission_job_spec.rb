require 'concurrent'

module Stash
  module Repo
    describe SubmissionJob do
      include Mocks::Aws
      include Mocks::Stripe

      attr_reader :job
      attr_reader :logger

      context 'high-level repo tests' do
        before(:each) do
          @job = SubmissionJob.new(resource_id: 17)

          @logger = instance_double(Logger)
          allow(Rails).to receive(:logger).and_return(logger)

          immediate_executor = Concurrent::ImmediateExecutor.new
          allow(Concurrent).to receive(:global_io_executor).and_return(immediate_executor)
        end

        after(:each) do
          allow(Concurrent).to receive(:global_io_executor).and_call_original
          allow(Rails).to receive(:logger).and_call_original
        end

        describe :submit_async do
          it 'delegates to :submit!, asynchronously' do
            result = SubmissionResult.new(resource_id: 17, request_desc: 'test', message: 'whee!')
            job.define_singleton_method(:submit!) { result }
            promise = job.submit_async(executor: Concurrent::ImmediateExecutor.new)
            raise promise.reason if promise.reason

            expect(promise.value).to be(result)
          end

          it 'handles errors' do
            job.define_singleton_method(:submit!) { raise Errno::ENOENT }
            promise = job.submit_async(executor: Concurrent::ImmediateExecutor.new)
            expect(promise.reason).to be_an(Errno::ENOENT)
          end
        end

        describe :log do
          it 'returns the Rails logger' do
            expect(job.logger).to be(logger)
          end
        end
      end

      context 'old Merritt-level tests ' do
        before(:each) do
          mock_aws!

          @logger = instance_double(Logger)
          allow(@logger).to receive(:debug)
          allow(@logger).to receive(:info)
          allow(@logger).to receive(:warn)
          allow(@logger).to receive(:error)

          @rails_logger = Rails.logger
          Rails.logger = @logger

          @landing_page_url = URI::HTTPS.build(host: 'stash.example.edu', path: '/doi:10.123/456').to_s

          @user = create(:user, tenant_id: 'dryad')
          @identifier = create(:identifier, identifier_type: 'DOI', identifier: '10.123/456', old_payment_system: true)
          @resource = create(:resource, identifier_id: @identifier.id, user: @user, tenant_id: 'dryad')
          allow(StashEngine::Resource).to receive(:find).with(@resource.id).and_return(@resource)

          @url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
          allow(@url_helpers).to(receive(:show_path)) { |identifier_str| "/#{identifier_str}" }

          @job = SubmissionJob.new(resource_id: @resource.id)
          allow(@job).to receive(:id_helper).and_return(OpenStruct.new(ensure_identifier: 'xxx'))

          allow(Stash::Repo::Repository).to receive(:hold_submissions?).and_return(false)
        end

        after(:each) do
          Rails.logger = @rails_logger
        end

        describe :submit! do

          before(:each) do
            allow(@resource).to receive(:upload_type).and_return(:files)
          end

          describe 'create' do

            it "doesn't submit the package if holding submissions for a restart" do
              allow(Stash::Repo::Repository).to receive(:hold_submissions?).and_return(true)
              expect(Stash::Repo::Repository).to receive(:update_repo_queue_state).with(state: 'rejected_shutting_down', resource_id: @resource.id)
              @job.submit!
            end

            it "doesn't reprocess previously submitted items (as shown by processing queue state)" do
              # not having working database and activerecord in these tests sucks
              allow(StashEngine::RepoQueueState).to receive(:where).and_return([1, 2])
              allow(StashEngine::RepoQueueState).to receive(:latest)
                .and_return({ present?: true, state: { enqueued?: true }.to_ostruct }.to_ostruct)
              expect(Stash::Repo::Repository).not_to receive(:update_repo_queue_state)
              @job.submit!
            end

            it 'returns a result' do
              result = @job.submit!
              expect(result).to be_a(Stash::Repo::SubmissionResult)
              expect(result.success?).to be_truthy
            end
          end

          describe 'update' do
            it 'returns a result' do
              result = @job.submit!
              expect(result).to be_a(Stash::Repo::SubmissionResult)
              expect(result.success?).to be_truthy
            end
          end

          describe 'error handling' do
            it 'fails on a bad resource ID' do
              bad_id = @resource.id * 17
              @job = SubmissionJob.new(resource_id: bad_id)
              allow(StashEngine::Resource).to receive(:find).with(bad_id).and_raise(ActiveRecord::RecordNotFound)
              expect_any_instance_of(StashEngine::Resource).not_to receive(:update)
              expect_any_instance_of(StashEngine::DataFile).not_to receive(:update)
              @job.submit!
            end
          end
        end

      end

      context 'create invoice' do
        let(:identifier) { create(:identifier, old_payment_system: false) }
        let(:resource) { create(:resource, tenant_id: 'dryad', identifier: identifier) }
        let(:author) { resource.owner_author }

        subject { SubmissionJob.new(resource_id: resource.id) }
        context 'with old payment system' do
          let(:identifier) { create(:identifier, old_payment_system: true) }

          it 'does not create any invoice' do
            expect(Stash::Payments::StripeInvoicer).not_to receive(:new)
            expect(subject.send(:handle_invoice_creation)).to be_nil
          end
        end

        context 'with new payment system' do
          context 'without a ResourcePayment record' do
            it 'does not create any invoice' do
              expect(Rails.logger).to receive(:warn).with("No payment found for resource ID #{resource.id}")
              expect(Stash::Payments::StripeInvoicer).not_to receive(:new)
              expect(subject.send(:handle_invoice_creation)).to be_nil
            end
          end

          context 'with ResourcePayment record set not to pay_with_invoice' do
            let!(:payment) { create(:resource_payment, resource: resource, pay_with_invoice: false) }

            it 'does not create any invoice' do
              expect(Rails.logger).to receive(:warn).with("Payment for resource ID #{resource.id} is not set to invoice")
              expect(Stash::Payments::StripeInvoicer).not_to receive(:new)
              expect(subject.send(:handle_invoice_creation)).to be_nil
            end
          end

          context 'with ResourcePayment record set to pay_with_invoice' do
            let(:invoice_id) { nil }
            let!(:payment) do
              create(:resource_payment,
                resource: resource,
                pay_with_invoice: true,
                invoice_id: invoice_id,
                invoice_details: {
                  'author_id' => author.id,
                  'customer_name' => 'Customer Name',
                  'customer_email' => 'customer.email@example.com'
                })
            end

            before do
              mock_stripe!
            end

            context 'when invoice_id is not set' do
              let(:invoice_id) { nil }

              it 'creates a new invoice' do
                subject.send(:handle_invoice_creation)
                expect(payment.reload.invoice_id).not_to be_nil
              end
            end

            context 'when invoice already exists' do
              let(:invoice_id) { 'some-id' }

              it 'returns nil' do
                expect {
                  subject.send(:handle_invoice_creation)
                }.not_to change {
                  payment.reload.invoice_id
                }
              end
            end
          end
        end
      end
    end
  end
end

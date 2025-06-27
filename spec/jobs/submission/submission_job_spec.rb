# spec/jobs/submission/submission_job_spec.rb
require 'rails_helper'

RSpec.describe Submission::SubmissionJob, type: :job do
  let!(:resource) { create(:resource) }
  let(:resource_id) { resource.id }
  let(:service_instance) { instance_double(Submission::ResourcesService) }

  before do
    allow(Submission::ResourcesService).to receive(:new).with(resource_id).and_return(service_instance)
    allow(service_instance).to receive(:update_repo_queue_state)
    allow(service_instance).to receive(:submit)
    allow(service_instance).to receive(:handle_failure)
  end

  describe 'sidekiq options' do
    it 'is on the correct queue and retry settings' do
      opts = described_class.get_sidekiq_options
      expect(opts['queue']).to eq(:submission)
      expect(opts['retry']).to eq(1)
      expect(opts['lock']).to eq(:until_and_while_executing)
    end
  end

  describe '#perform' do
    subject(:perform_job) { described_class.new.perform(resource_id) }

    context 'when submissions are held' do
      before { allow(service_instance).to receive(:hold_submissions?).and_return(true) }

      it 'marks as rejected_shutting_down and skips submission' do
        expect(service_instance).to receive(:update_repo_queue_state).with(state: 'rejected_shutting_down')
        expect(service_instance).not_to receive(:submit)
        perform_job
      end
    end

    context 'when submission is allowed' do
      before do
        allow(service_instance).to receive(:hold_submissions?).and_return(false)
      end

      context 'when previously submitted' do
        it 'marks as enqueued and calls submit' do
          expect(service_instance).to receive(:update_repo_queue_state).with(state: 'enqueued')
          expect(service_instance).to receive(:submit)
          perform_job
        end
      end

      context 'when previously submitted and already processing' do
        before do
          create(:repo_queue_state, resource: resource, state: 'processing')
          create(:repo_queue_state, resource: resource, state: 'enqueued') # latest one
        end

        it 'does not call submit and deletes the latest enqueued queue' do
          latest = StashEngine::RepoQueueState.where(resource_id: resource_id, state: 'enqueued').last
          expect(service_instance).not_to receive(:submit)
          expect { perform_job }.to change { StashEngine::RepoQueueState.exists?(latest.id) }.from(true).to(false)
        end
      end

      context 'when an error is raised during submission' do
        let(:error) { StandardError.new('boom') }

        before do
          allow(service_instance).to receive(:submit).and_raise(error)
        end

        it 'calls handle_failure' do
          expect(service_instance).to receive(:handle_failure) do |result|
            expect(result).to be_a(Stash::Repo::SubmissionResult)
            expect(result.resource_id).to eq(resource_id)
            expect(result.error.message).to eq('boom')
          end

          perform_job
        end
      end
    end
  end
end

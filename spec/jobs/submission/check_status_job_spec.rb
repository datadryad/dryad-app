# spec/jobs/submission/check_status_job_spec.rb
require 'rails_helper'

RSpec.describe Submission::CheckStatusJob, type: :job do
  let(:resource) { create(:resource) }
  let(:job_state) { 'enqueued' }
  let!(:queue_state) { create(:repo_queue_state, resource: resource, state: job_state) }

  subject(:perform_job) { described_class.new.perform(resource.id) }

  before do
    allow(Rails.logger).to receive(:info)
    allow_any_instance_of(described_class).to receive(:remove_redis_key).and_return(1)
  end

  describe 'sidekiq options' do
    it 'has the correct queue and retry settings' do
      opts = described_class.get_sidekiq_options
      expect(opts['queue']).to eq(:submission_check)
      expect(opts['retry']).to eq(2)
    end
  end

  context 'when state is not processing or provisional_complete' do
    it 'does nothing' do
      expect(resource.repo_queue_states.last.state).to eq('enqueued')
      expect(Rails.logger).not_to receive(:info)
      perform_job
    end
  end

  context 'when state is processing' do
    let(:job_state) { 'processing' }

    context 'and possibly_set_as_completed returns true' do
      before do
        allow_any_instance_of(StashEngine::RepoQueueState).to receive(:possibly_set_as_completed).and_return(true)
      end

      it 'logs finalized availability' do
        perform_job
        expect(Rails.logger).to have_received(:info).with("  Resource #{resource.id} available in storage and finalized")
      end
    end

    context 'and possibly_set_as_completed returns false' do
      before do
        allow_any_instance_of(StashEngine::RepoQueueState).to receive(:possibly_set_as_completed).and_return(false)
      end

      it 'logs not yet available' do
        perform_job
        expect(Rails.logger).to have_received(:info).with("  Resource #{resource.id} not yet available")
      end
    end
  end

  context 'when state is provisional_complete' do
    let(:job_state) { 'provisional_complete' }

    before do
      allow_any_instance_of(StashEngine::RepoQueueState).to receive(:possibly_set_as_completed).and_return(true)
    end

    it 'logs finalized availability' do
      perform_job
      expect(Rails.logger).to have_received(:info).with("  Resource #{resource.id} available in storage and finalized")
    end
  end
end

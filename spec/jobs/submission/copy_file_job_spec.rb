# spec/jobs/submission/copy_file_job_spec.rb
require 'rails_helper'

RSpec.describe Submission::CopyFileJob, type: :job do
  let(:resource) { create(:resource) }
  let(:data_file) { create(:data_file, resource: resource, download_filename: 'file.txt') }
  let!(:queue_state) { create(:repo_queue_state, resource: resource) }

  let(:files_service) { instance_double(Submission::FilesService) }

  before do
    allow(Submission::FilesService).to receive(:new).with(data_file).and_return(files_service)
    allow(files_service).to receive(:copy_file)
    allow(Submission::CheckStatusJob).to receive(:perform_in)
    allow(StashEngine::UserMailer).to receive_message_chain(:error_report, :deliver_now)
    allow(Sidekiq).to receive(:redis).and_yield(double('Redis', decr: 2))
  end

  describe 'sidekiq options' do
    it 'is on the correct queue and retry settings' do
      opts = described_class.get_sidekiq_options
      expect(opts['queue']).to eq(:submission_file)
      expect(opts['retry']).to eq(1)
      expect(opts['lock']).to eq(:until_and_while_executing)
    end
  end

  describe '#perform' do
    subject(:perform_job) { described_class.new.perform(data_file.id) }

    context 'when file is copied successfully' do
      before do
        allow(Sidekiq).to receive(:redis).and_yield(double('Redis', decr: 0))
      end

      it 'calls FilesService#copy_file and enqueues CheckStatusJob' do
        expect(files_service).to receive(:copy_file)
        expect(Submission::CheckStatusJob).to receive(:perform_async).with(resource.id)
        expect(ArchiveAnalyzerJob).not_to receive(:perform_async)
        perform_job
      end

      context 'when the file is an archive' do
        let(:data_file) { create(:data_file, resource: resource, download_filename: 'archive.zip') }

        it 'calls FilesService#copy_file and enqueues CheckStatusJob' do
          expect(ArchiveAnalyzerJob).to receive(:perform_async).with(data_file.id)
          perform_job
        end
      end
    end

    context 'when copy takes too long (timeout)' do
      before do
        allow(files_service).to receive(:copy_file).and_raise(Timeout::Error)
      end

      it 'creates an errored repo_queue_state and sends an email' do
        expect do
          expect { perform_job }.to raise_error(StandardError, /processing for more than a day/)
        end.to change { StashEngine::RepoQueueState.where(resource_id: resource.id, state: 'errored').count }.by(1)

        expect(StashEngine::UserMailer).to have_received(:error_report).with(resource, instance_of(StandardError))
      end
    end
  end

end

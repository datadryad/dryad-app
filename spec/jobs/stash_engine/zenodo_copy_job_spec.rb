require 'byebug'

require 'rails_helper'
require 'fileutils'

RSpec.configure(&:infer_spec_type_from_file_location!)

module StashEngine
  RSpec.describe ZenodoCopyJob do

    before(:each) do
      @resource = create(:resource)
      @new_zen = double('newZenodo')
      allow(Stash::ZenodoReplicate::Copier).to receive(:new).and_return(@new_zen)
    end

    describe '#perform' do

      it 'calls to add to zenodo if in correct states' do
        create(:zenodo_copy, state: 'enqueued', identifier_id: @resource.identifier_id, resource_id: @resource.id)
        expect(@new_zen).to receive(:add_to_zenodo)
        zcj = ZenodoCopyJob.new
        zcj.perform(@resource.id)
      end

      it "doesn't add to zenodo if no zenodo_copy record is set" do
        expect(@new_zen).not_to receive(:add_to_zenodo)
        zcj = ZenodoCopyJob.new
        zcj.perform(@resource.id)
      end

      it "doesn't add to zenodo if resource is nil" do
        expect(@new_zen).not_to receive(:add_to_zenodo)
        zcj = ZenodoCopyJob.new
        zcj.perform(nil)
      end

      it "doesn't add to zenodo if isn't enqueued state" do
        create(:zenodo_copy, state: 'finished', identifier_id: @resource.identifier_id, resource_id: @resource.id)
        expect(@new_zen).not_to receive(:add_to_zenodo)
        zcj = ZenodoCopyJob.new
        zcj.perform(@resource.id)
      end
    end

    describe 'self.should_defer?(resource:)' do
      before(:each) do
        FileUtils.rm_f(ZenodoCopyJob::DEFERRED_TOUCH_FILE)
      end

      it 'returns true and sets deferred if defer file exists' do
        FileUtils.touch(ZenodoCopyJob::DEFERRED_TOUCH_FILE)
        create(:zenodo_copy, state: 'enqueued', identifier_id: @resource.identifier_id, resource_id: @resource.id)
        expect(ZenodoCopyJob.should_defer?(resource: @resource)).to eq(true)
        @resource.reload
        expect(@resource.zenodo_copies.data.first.state).to eq('deferred')
        FileUtils.rm(ZenodoCopyJob::DEFERRED_TOUCH_FILE)
      end

      it "returns false and doesn't defer if defer file doesn't exist" do
        create(:zenodo_copy, state: 'enqueued', identifier_id: @resource.identifier_id, resource_id: @resource.id)
        expect(ZenodoCopyJob.should_defer?(resource: @resource)).to eq(false)
        @resource.reload
        expect(@resource.zenodo_copies.data.first.state).to eq('enqueued')
      end
    end

    describe 'self.enqueue_deferred' do
      include ActiveJob::TestHelper

      it 're-enqueues the deferred items' do
        create(:zenodo_copy, state: 'deferred', identifier_id: @resource.identifier_id, resource_id: @resource.id)
        ZenodoCopyJob.enqueue_deferred
        @resource.reload
        expect(@resource.zenodo_copies.data.first.state).to eq('enqueued')
        expect(enqueued_jobs).to match([a_hash_including(job: StashEngine::ZenodoCopyJob, args: [@resource.id], queue: 'zenodo_copy')])
      end

      after(:each) do
        clear_enqueued_jobs
      end
    end

  end
end

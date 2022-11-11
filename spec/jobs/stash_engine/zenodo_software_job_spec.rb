require 'byebug'

require 'rails_helper'
require 'fileutils'

RSpec.configure(&:infer_spec_type_from_file_location!)

module StashEngine
  RSpec.describe ZenodoSoftwareJob do

    before(:each) do
      @resource = create(:resource)
      @new_zen = double('newZenodo')
      allow(Stash::ZenodoSoftware::Copier).to receive(:new).and_return(@new_zen)
    end

    describe '#perform' do

      it 'calls to add to zenodo' do
        zc = create(:zenodo_copy, state: 'enqueued', copy_type: 'software', identifier_id: @resource.identifier_id, resource_id: @resource.id)
        expect(@new_zen).to receive(:add_to_zenodo)
        zsj = ZenodoSoftwareJob.new
        zsj.perform(zc.id)
      end
    end

    describe 'self.should_defer?(resource:)' do
      before(:each) do
        FileUtils.rm_f(ZenodoCopyJob::DEFERRED_TOUCH_FILE)
        @zsj = ZenodoSoftwareJob.new
        @zc = create(:zenodo_copy, state: 'enqueued', copy_type: 'software', identifier_id: @resource.identifier_id, resource_id: @resource.id)
        @zsj.job_entry = @zc
      end

      it 'returns true and sets deferred if defer file exists' do
        FileUtils.touch(ZenodoCopyJob::DEFERRED_TOUCH_FILE)
        expect(@zsj.should_defer?).to eq(true)
        expect(@zc.state).to eq('deferred')
        FileUtils.rm(ZenodoCopyJob::DEFERRED_TOUCH_FILE)
      end

      it "returns false and doesn't defer if defer file doesn't exist" do
        expect(@zsj.should_defer?).to eq(false)
        expect(@zc.state).to eq('enqueued')
      end
    end

    describe 'self.enqueue_deferred' do
      include ActiveJob::TestHelper

      it 're-enqueues the deferred items' do
        zc = create(:zenodo_copy, state: 'deferred', copy_type: 'software', identifier_id: @resource.identifier_id, resource_id: @resource.id)
        ZenodoSoftwareJob.enqueue_deferred
        @resource.reload
        expect(@resource.zenodo_copies.software.first.state).to eq('enqueued')
        expect(enqueued_jobs).to match([a_hash_including(job: StashEngine::ZenodoSoftwareJob, args: [zc.id], queue: 'zenodo_software')])
      end

      after(:each) do
        clear_enqueued_jobs
      end
    end

  end
end

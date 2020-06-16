require 'stash/zenodo_software'

module StashEngine
  class ZenodoSoftwareJob < ::ActiveJob::Base
    queue_as :zenodo_software

    # unlike the zenodo_copy_job, this one takes a ZenodoCopy.id instead of a resource_id since it needs a little more info
    # and may do multiple actions on the same resource (such as sending and then publishing the same resource)
    def perform(*args)
      @job_entry = StashEngine::ZenodoCopy.where(id: args[0]).first
      return if @job_entry.nil? || should_defer?

      zr = Stash::ZenodoSoftware::Copier.new(copy_id: @job_entry.id)
      zr.add_to_zenodo
    end

    def should_defer?
      if File.exist?(ZenodoCopyJob::DEFERRED_TOUCH_FILE) # use same touch file for both software and replication for Zenodo
        @job.update(state: 'deferred')
        return true
      end
      false
    end

    def self.enqueue_deferred
      StashEngine::ZenodoCopy.software.where(state: 'deferred').each do |zc|
        zc.update(state: 'enqueued')
        perform_later(zc.id)
      end
    end
  end
end

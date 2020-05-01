require 'stash/zenodo_replicate'

# module StashEngine
# class ZenodoSoftwareJob < ::ActiveJob::Base
#     queue_as :zenodo_software

# I'm just copying this in for now, but will figure out how to combine or modify later.

# DEFERRED_TOUCH_FILE = Rails.root.join('..', 'defer_jobs.txt').to_s

# There is no real way to do a graceful pause of possibly long-running jobs ahead of a restart with ActiveJob or with
# delayed_job, so the only real solution is to add another status in a database state for
# a long running item such as 'deferred' outside of the queuing system (where I think it would naturally belong).
#
# Then before a shutdown/reboot make some logic that checks for the presence of a file like 'defer_jobs.txt'.
#
# If it exists then change the state to 'deferred' on the item and return early so it doesn't run and wait for
# any processing/in-progress to drain before restarting the workers.
#
# Then after the workers have restarted, have a method to re-enqueue the deferred jobs so they will get processed.

# the only argument for this is really the resource ID to copy
# def perform(*args)
# resource = StashEngine::Resource.where(id: args[0]).first
# return if resource.nil? || resource&.zenodo_copies.software.first&.state != 'enqueued' || self.class.should_defer?(resource: resource)

# zr = Stash::ZenodoReplicate::Resource.new(resource: resource)
# zr.add_to_zenodo
#     end

#     def self.should_defer?(resource:)
# zc = resource.software.first.zenodo_copy
# if File.exist?(DEFERRED_TOUCH_FILE)
#   zc.update(state: 'deferred')
#   return true
# end
# false
#   end

#    def self.enqueue_deferred
# StashEngine::ZenodoCopy.where(state: 'deferred').each do |zc|
#   zc.update(state: 'enqueued')
#   perform_later(zc.resource_id)
# end
#    end
#   end
# end

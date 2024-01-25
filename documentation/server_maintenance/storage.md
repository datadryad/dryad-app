Dryad file storage
=====================

Dryad stores data files in cloud storage. The primary
storage for Dryad deposits is in an S3 bucket that lives near the production UI servers.


Interactions with storage
===========================

Submissions to the storage system can be started and stopped from the
[GUI Submission Queue page](https://datadryad.org/stash/submission_queue). However,
actions on this page will only affect the single server that you are
attached to, and not all servers in a load-balanced system. (Note
the long_jobs.dryad script will also do this,
also, on the current server). 


Stopping submissions
-----------------------------

To pause submissions, on each server:
```
touch /apps/dryad/apps/ui/releases/hold-submissions.txt
```

This will put any queued submissions into the
`rejected_shutting_down` state on this server, which means they will
not be submitted right now, but you can restart them again afterward.


Restarting submissions from hold or errors
-------------------------------------------

To restart submissions, on each server:
```
rm /apps/dryad/apps/ui/releases/hold-submissions.txt
```

THEN, on one server, in the Rails console:
```
resource_ids =
  StashEngine::RepoQueueState.latest_per_resource.where(state: 'rejected_shutting_down').order(:updated_at).map(&:resource_id)
resource_ids.each do |res_id|
  StashEngine.repository.submit(resource_id: res_id)
end
```

If storage had errors, you can use a similar process, but you must remove any `processing` entries for
the RepoQueueState:
```
resource_ids =
  StashEngine::RepoQueueState.latest_per_resource.where(state: 'errored').order(:updated_at).map(&:resource_id)
resource_ids.each do |res_id|
 repo_queue_id = StashEngine::RepoQueueState.where(state: 'processing', resource_id: res_id).last.id
 StashEngine::RepoQueueState.find(repo_queue_id).destroy
 StashEngine.repository.submit(resource_id: res_id)
end
```

Async download check
----------------------------

This error typically means that the account being used by the Dryad UI
to access storage does not have permisisons for the object being
requested.


Submission status
=================

The submission status checker runs from a daemon on our 01 servers, as something that
can be started manually from a rake task like:
```
RAILS_ENV=<environment> bundle exec rails merritt_status:update
```

However, it will start automatically from systemd startup and
can be managed through it.


Technical processes
===================

To be as fault-tolerant as possible, the storage system consists of two phases:
submission to the storage, and checking that storage was successful. The
majority of the work is done in the submission phase, with only minor cleanup in
the checking phase.


Submission process
------------------

1. GUI POSTs to `/stash_datacite/resources/submission`
2. Routes to `StashDatacite::ResourcesController#submission`
   1. Does some validation and setup
   2. Hands off to `StashEngine.repository.submit`
   3. Kicks off transfer of Zenodo content
   4. Sends the GUI user to the correct URL while they wait for processing to complete
3. `StashEngine.repository.submit == Stash::Repo::Repository.submit`
   1. Sets the resource state to `processing`
   2. Creates a SubmissionJob
   3. Adds the resource to the queue `stash_engine_repo_queue_states`
   4. Submits the job for asynchronous completion
   5. Handles success or failure of the job


Checker process
----------------

1. User or cron runs `merritt_status:update`
2. Takes the latest unfinished jobs from `stash_engine_repo_queue_states` for each resource and checks them
   1. `RepoQueueState.possibly_set_as_completed` checks whether resource is avaialable in storage, and if it is:
      1. Calls `Repository.harvested` to update the resource state
      2. Registers the job in the queue as completed
      3. Deletes temporary files
   2. If the job has been processing for a full day, mark it as errored and email the admins

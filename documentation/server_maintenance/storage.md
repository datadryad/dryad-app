Dryad file storage
=====================

Dryad stores data files in cloud storage. The primary
storage for Dryad deposits is in an S3 bucket that lives near the production UI servers.


Interactions with storage
===========================

Submissions to the storage system can be started and stopped from the
[GUI Submission Queue page](https://datadryad.org/submission_queue). However,
actions on this page will only affect the single server that you are
attached to, and not all servers in a load-balanced system. (Note
the long_jobs.dryad script will also do this,
also, on the current server). 


Stopping submissions
-----------------------------

To pause submissions, on each server:
```
touch /home/ec2-user/deploy/releases/hold-submissions.txt
```

This will put any queued submissions into the
`rejected_shutting_down` state on this server, which means they will
not be submitted right now, but you can restart them again afterward.


Restarting submissions from hold or errors
-------------------------------------------

To restart submissions, on each server:
```
rm /home/ec2-user/deploy/releases/hold-submissions.txt
```

THEN, on one server, in the Rails console:
```ruby
resource_ids =
  StashEngine::RepoQueueState.latest_per_resource.where(state: 'rejected_shutting_down').order(:updated_at).map(&:resource_id)
resource_ids.each do |res_id|
   Submission::ResourcesService.new(res_id).trigger_submission
end
```

If storage had errors, you can use a similar process, but you must remove any `processing` entries for
the RepoQueueState:
```ruby
resource_ids =
  StashEngine::RepoQueueState.latest_per_resource.where(state: 'errored').order(:updated_at).map(&:resource_id)
resource_ids.each do |res_id|
  repo_queue_id = StashEngine::RepoQueueState.where(state: 'processing', resource_id: res_id).last.id
  StashEngine::RepoQueueState.find(repo_queue_id).destroy
  Submission::ResourcesService.new(res_id).trigger_submission
end
```

Alternatively, you may sometimes complete a submission by getting a copy of the RepoQueueState object and forcing it to complete.
```
r=StashEngine::RepoQueueState.find(<id_num>)
r.possibly_set_as_completed
```


Async download check
----------------------------

This error typically means that the account being used by the Dryad UI
to access storage does not have permisisons for the object being
requested.


Submission status
=================

The submission status checker is another Sidekiq background job `Submission::CheckStatusJob`
and is triggered automatically once all the files are moved to permanent storage.


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
   2. Hands off to `Submission::SubmissionJob`
   3. Kicks off transfer of Zenodo content
   4. Sends the GUI user to the correct URL while they wait for processing to complete
3. `Submission::SubmissionJob` is a background job which
   1. Sets the resource state to `processing`
   2. Creates a SubmissionJob
   3. Adds the resource to the queue `stash_engine_repo_queue_states`
   4. Submits the job for asynchronous completion
   5. Handles success or failure of the job
4. `Submission::CopyFileJob` is another background job which
   1. Copies subscription files to permanent storage
   2. Is enqueued by `Submission::SubmissionJob` for each of the files in the resource
   3. Each job copies just one file
   4. Multiple files are copied in parallel to speed up the process
   5. Last job in the chain calls `Submission::CheckStatusJob`
5. `Submission::CheckStatusJob` is a background job which
   1. Is called just once per submission
   2. Is responsible for updating submission status and cleaning temporary files


Checker process
----------------
Submission status is checked by `Submission::CheckStatusJob` background job which
1. Checks using `RepoQueueState.possibly_set_as_completed` resource is available in storage, and if it is:
    1. Calls `Repository.harvested` to update the resource state
    2. Registers the job in the queue as completed
    3. Deletes temporary files
2. If the job has been processing for a full day, mark it as errored and email the admins


Download process
----------------

1. `DownloadsController.file_stream` starts the process.
2. Passes to `Stash::Download::FilePresigned.download`
3. Gets the actual download URL from `DataFile.s3_permanent_presigned_path`
   1. Locates the original DataFile object (the one with this filename that was `created`)
   2. Checks for the file in the v3 hierarchy (v3/<resource_id>/<filename>)
   3. Tries to find older files in the Merritt hierarchy using `DataFile.mrt_bucket_path`

Note: If the Resource has a Merritt location for `download_uri`, but the code
isn't able to find it, the Resource might have the wrong Merritt version number,
in which case you can update the `merritt_version` in the `stash_engine_versions` table.

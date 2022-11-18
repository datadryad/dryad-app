Dryad–Merritt storage
=====================

Storage and replication for Dryad are managed by Merritt.  The primary
storage for Dryad deposits is in an S3 bucket administered and paid
for by Dryad, while Dash deposits (i.e., deposits from UC tenants),
are stored in an S3 bucket administered by CDL.


Interactions with Merritt
===========================

Submissions to Merritt can be started and stopped from the
[GUI Submission Queue page](https://datadryad.org/stash/submission_queue). However,
actions on this page will only affect the single server that you are
attached to, and not all servers in a load-balanced system. (Note
the long_jobs.dryad script will also do this,
also, on the current server). 

Stopping Merritt Submissions
-----------------------------

To pause Merritt submissions, on each server:
```
touch /apps/dryad/apps/ui/releases/hold-submissions.txt
```

This will put any queued submissions into the
`rejected_shutting_down` state on this server, which means they will
not be submitted right now, but you can restart them again afterward.

(Re)Starting Merritt Submissions from hold or Merritt errors
------------------------------------------------------------

To restart Merrit submissions, on each server:
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

If Merritt had errors, you can use a similar process, but you must remove any `processing` entries for
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

Merrit async download check
----------------------------

This error typically means that the account being used by the Dryad UI
to access Merritt does not have permisisons for the object being
requested. This is often because either the Dryad UI or the object in
Merritt is using a UC-based account, while the other is using a non-UC account.


Merritt Submission Status
==============

Checking Merritt Submission Status runs from a daemon on our 01 servers, as something that
can be started manually from a rake task like:
```
RAILS_ENV=<environment> bundle exec rails merritt_status:update
```

However, it will start automatically from systemd startup and
can be managed through it.


# Zenodo extra copies

For environments that send datasets to Zenodo, the process of
transferring the data only lives on one server (e.g., stage-c, but not stage-a).
On servers where the transfer process lives, detailed documentation
can be found in `/dryad/init.d/README.delayed_job.md`.

## Some things errored and I want to send them through again
- Go to the Database table *stash_engine_zenodo_copies*
- Look up item(s) by *identifier_id*
- Reset the *error* status to *deferred* status instead, also reset the *retries* to 0 (it will stop retrying at 3).
- If there are more rows with error status for that identifier (such as "out of order" errors), then reset each of them to *deferred* as well as the *retries* to 0.
- on the -2c server, execute `~/bin/long_jobs.dryad restart`.  That will re-enqueue the *deferred* for sending to zenodo again.
- If items for the same dataset arrive out of order or before an earlier one finishes processing, the later one may still error.   Repeat resetting the error statuses to *deferred* and rerunning `long_jobs.dryad restart` until all versions of the the error have gone through (or identify other causes for the error if they are not fixed by resubmitting).


## It's not processing? Why? Look at this stuff
- (On 2c) Check `sudo systemctl status delayed_job` for status or
  start the daemon with `sudo systemctl start delayed_job`
- Delayed jobs has a bare work queue in the table `delayed_jobs`.  Jobs should appear here until processed successfully and then will be deleted on success.
- The application state of the zenodo jobs is maintained in `stash_engine_zenodo_copies` and also contains important info such as the deposition id (zenodo's internal id)
- Most errors and stack traces should be saved into the error field in the table above so we don't have to spend hours digging through logs to figure out problems

## We're about to have a maintenance, shutdow or restart, what do I do?
- (On 2c) "pause" or "drain" the jobs at least a few hours or more ahead so they don't get cut off in the middle of something that takes many hours to process.
- Check status with `~/bin/long_jobs.dryad status`
- Let jobs drain out with `~/bin/long_jobs.dryad drain`.  This really just touches two files in the `~/app/ui/releases` directory. The files are: `defer_jobs.txt` (zenodo replication) and `hold-submissions.txt` (Merritt submissions).  When these files are present then the internal state of these is put into a `defered` or `rejected-shutting-down` when it's their turn to run.  These states are in their own tables and not the delayed_job work queue because the delayed_job queue is very simple and dumb.

## We just finished maintenance, what do I do?
- (On 2c) `~/bin/long_jobs.dryad restart`  .  This takes the jobs that were rejected/deferred and resets their status to 'enqueued' and re-inserts them into the work queue.
- The deferred job things (zenodo) only runs on one server (2c), but currently the Merritt submission queue runs on both inside the web server processes so it is more complicated.
- For Merritt queues:
  - Be sure the `~/app/ui/releases/hold-submissions.txt` files are deleted.
  - Look at the Merritt queue page in the UI and note which server you're accessing.
  - For the 'rejected shutting down' jobs showing as the other server (in `stash_engine_repo_queue_states`, manipulate the database to set the latest state's hostname to the server you're on.
  - Click "Restart submissions which were shut down gracefully".  It should re-enqueue them on your current server.

## Example of manually submitting a Zenodo copy from the console

```
RAILS_ENV=local_dev bin/delayed_job start
```

from RAILS_ENV=local_dev rails console:
```
resource = StashEngine::Resource.find(<id>)
resource.send_to_zenodo
```

You can now check the stash_engine_zenodo_copies and delayed_jobs tables for status
or if you want to look at the item on zenodo (it has their id in the table).

## ActiveJob / Delayed Job Background

The Rails framework ActiveJob libraries are meant to address these
issues and are a common standard way to address background processing
for a Rails application.  ActiveJob works as a wrapper around the most
popular backends for asynchronous queuing and processing that are most
commonly mentioned: Sidekiq, Resque and (Shopify's) Delayed Job.  If
using the ActiveJob interface, the backend can be switched out with
only a bit of configuration change if more scaling is needed.

Delayed Job is attractive since it saves its queue in a table in the
application's MySQL database and doesn't require another server
technology (Redis) to be installed and managed.  It also doesn't
involve extra worry for saving queue state like the technologies that
rely on Redis which is an in-memory store and may not save the queue
in the case of an irregular exit or crash.

The Redis-backed asyncronous queuing systems apparently are very fast
and can handlea huge numbers of queuing requests with ease, but I
believe are all overkill for the few dozens to hundreds or even few
thousands of queueing jobs we'll likely do every day (this scale is
very small compared to how some people use these systems).

Delayed Job saves queue state to the database (from request by
ActiveJob) and a separate independent Delayed Job daemon process picks
up jobs off the queue and processes them so they run independently of
the web server processes.  The items enqueued can be of all different
types and it can contain multiple different named queues for jobs (as
well as priorities, time scheduling and other features).  While the
application code needs to be present, the Delayed Job queue processor
could run on any server that has access to the database and doesn't
even need to run on a UI server and probably wouldn't use most of the
application code.

Some background info on delayed job

```
https://github.com/collectiveidea/delayed_job
https://axiomq.com/blog/deal-with-long-running-rails-tasks-with-delayed-job/
https://github.com/collectiveidea/delayed_job/issues/776
https://github.com/collectiveidea/delayed_job/wiki/Delayed-job-command-details
https://guides.rubyonrails.org/v4.2/active_job_basics.html

# to start and stop locally
RAILS_ENV=local_dev bin/delayed_job start
RAILS_ENV=local_dev bin/delayed_job stop
-n, --number_of_workers=workers
```

ActiveJob is really just a work queue and doesn't automatically track application states.

We really may want to move our Merritt submissions to use something
like this rather than the expansion I made to David's home-baked
queueing system which still runs inside the UI server processes and
can have problems if the UI server goes down at an inopportune time.


# Zenodo extra copies

For environments that send datasets to Zenodo, the process of
transferring the data only lives on one server (e.g., stage-c, but not stage-a).
On servers where the transfer process lives, detailed documentation
can be found in `/dryad/init.d/README.delayed_job.md`.

## Some things errored and I want to send them through again
- Go to the *Admin | Zenodo Submissions* menu, find the item in the list and click *resend*.
- Click the "Reset stalled to error state" which finds anything incorrectly showing running still and reset it to error.
- If there are multiple items for the same identifier, you will need to send them through
  in order for the same copy type (see the id column for order)
- You can click the link for an item under the "ident.id" to just seem replication jobs for that identifier.
  

## It's not processing? Why? Look at this stuff
- On second server (2c or 2) rather than first (2a or 1).
- OLD SERVERS: `cd ~/apps/ui/current` and then `RAILS_ENV=production bundle exec bin/delayed_job -n 3 start` (or stop).
- NEW SERVERS: Check `sudo systemctl status delayed_job` for status or
  start the daemon with `sudo systemctl start delayed_job`
- There may be long (or stalled) jobs running on all workers.  The delayed_job table shows what is actually running in delayed job.
  Sometimes restarting delayed_job may help.   Some items in the queue may show SIGTERM in their error column in the delayed_job table
  And you can delete it there and resubmit in the admin page again after if you want.

## We're about to have a maintenance, shutdow or restart, what do I do?
- (On 2c) "pause" or "drain" the jobs a bit ahead so they don't get cut off in the middle.  If they do get cut off you can
  resend them afterwards.
- If you deploy, the delayed_job daemon is stopped before deploy and restarted after deploy. (on old servers--Ashley is looking at how
  to do this with her puppeting).
- Check status with `~/bin/long_jobs.dryad status`
- Let jobs drain out with `~/bin/long_jobs.dryad drain`.  This really just touches two files in the `~/app/ui/releases` directory.
  The files are: `defer_jobs.txt` (zenodo replication) and `hold-submissions.txt` (Merritt submissions).  When these files are present then the internal state of these is put into a `defered` or `rejected-shutting-down` when it's their turn to run.  These states are in their own tables and not the delayed_job work queue because the delayed_job queue is very simple and dumb.

## We just finished maintenance, what do I do?
- (On 2c) `~/bin/long_jobs.dryad restart`.  This takes the jobs that were rejected/deferred and resets their status to 'enqueued' and re-inserts them into the work queue.
- The deferred job things (zenodo) only runs on one server (2c), but currently the Merritt submission queue runs on both inside the web server processes so it is more complicated.
- Start delayed_job if it's not running.  It should get restarted if you deployed code (old servers). 
- For Merritt queues:
  - Be sure the `~/app/ui/releases/hold-submissions.txt` files are deleted.
  - Look at the Merritt queue page in the UI and note which server you're accessing.
  - For the 'rejected shutting down' jobs showing as the other server (in `stash_engine_repo_queue_states`, manipulate the database to set the latest state's hostname to the server you're on.
  - Click "Restart submissions which were shut down gracefully".  It should re-enqueue them on your current server.

## ActiveJob / Delayed Job Background

The Rails framework ActiveJob libraries are meant to be a common standard
way to address background processing
for a Rails application.  ActiveJob works as a wrapper around the most
popular backends for asynchronous queuing and processing that are most
commonly mentioned: Sidekiq, Resque and (Shopify's) Delayed Job.  If
using the ActiveJob interface, the backend can be switched out with
only a bit of configuration change if more scaling is needed.

Delayed Job is attractive since it saves its queue in a table in the
application's MySQL database and doesn't require another server
technology (Redis) to be installed and managed.

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

